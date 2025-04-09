#include "datacenter.h"
#include <QFile>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDateTime>
#include <QDebug>

DataCenter::DataCenter(QObject *parent) : QObject(parent) {
    load();
}

QJsonObject DataCenter::data() const {
    return m_data;
}

void DataCenter::load() {
    QFile file(getFilePath());

    // Intentar cargar archivo existente
    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        file.close();

        if (!doc.isNull() && doc.isObject()) {
            m_data = doc.object();

            // Verificar y corregir datos si es necesario
            if (!m_data.contains("exercises") || m_data["exercises"].toArray().isEmpty()) {
                loadDefaultData();
            } else {
                ensureHistoriesExist();
            }
        } else {
            loadDefaultData();
        }
    } else {
        loadDefaultData();
    }

    save(); // Guardar por si hubo correcciones
    qDebug() << "Datos cargados:\n" << QJsonDocument(m_data).toJson(QJsonDocument::Indented);
    emit dataChanged();
}

void DataCenter::ensureHistoriesExist() {
    QJsonArray exercises = m_data["exercises"].toArray();
    bool modified = false;

    for (auto&& exValue : exercises) {
        QJsonObject exercise = exValue.toObject();
        QJsonArray history = exercise["history"].toArray();

        if (history.isEmpty()) {
            QJsonObject record;
            record["timestamp"] = exercise["lastUpdated"].toString();
            record["value"] = exercise["currentValue"].toDouble();
            record["unit"] = exercise["unit"].toString();
            record["repetitions"] = exercise["repetitions"].toInt();

            history.append(record);
            exercise["history"] = history;
            exValue = exercise;
            modified = true;
        }
    }

    if (modified) {
        m_data["exercises"] = exercises;
    }
}

void DataCenter::save() {
    QFile file(getFilePath());
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(m_data).toJson());
        file.close();
    }
}

void DataCenter::addExercise(const QString& name, const QString& muscleGroup,
                             double value, const QString& unit, int reps) {
    QJsonArray exercises = m_data["exercises"].toArray();
    QDateTime now = QDateTime::currentDateTime();

    QJsonObject newExercise {
        {"name", name},
        {"muscleGroup", muscleGroup},
        {"currentValue", value},
        {"unit", unit},
        {"repetitions", reps},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{QJsonObject{
                        {"timestamp", now.toString(Qt::ISODate)},
                        {"value", value},
                        {"unit", unit},
                        {"repetitions", reps}
                    }}}
    };

    exercises.append(newExercise);
    m_data["exercises"] = exercises;
    save();
    emit dataChanged();
}

void DataCenter::updateExercise(int index, double value, int reps) {
    QJsonArray exercises = m_data["exercises"].toArray();
    if (index < 0 || index >= exercises.size()) return;

    QJsonObject exercise = exercises[index].toObject();
    QDateTime now = QDateTime::currentDateTime();

    // Añadir al historial
    QJsonArray history = exercise["history"].toArray();
    history.prepend(QJsonObject{
        {"timestamp", exercise["lastUpdated"].toString()},
        {"value", exercise["currentValue"].toDouble()},
        {"unit", exercise["unit"].toString()},
        {"repetitions", exercise["repetitions"].toInt()}
    });

    // Actualizar ejercicio
    exercise["currentValue"] = value;
    exercise["repetitions"] = reps;
    exercise["lastUpdated"] = now.toString(Qt::ISODate);
    exercise["history"] = history;

    exercises.replace(index, exercise);
    m_data["exercises"] = exercises;
    save();
    emit dataChanged();
}

void DataCenter::removeExercise(int index) {
    QJsonArray exercises = m_data["exercises"].toArray();
    if (index < 0 || index >= exercises.size()) return;

    exercises.removeAt(index);
    m_data["exercises"] = exercises;
    save();
    emit dataChanged();
}

void DataCenter::deleteFile() {
    QFile file(getFilePath());
    if (file.exists() && file.remove()) {
        loadDefaultData();
        save();
    }
}

QString DataCenter::getFilePath() const {
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/exercises.json";
}

void DataCenter::loadDefaultData() {
    QDateTime now = QDateTime::currentDateTime();
    QDateTime yesterday = now.addDays(-1);
    QDateTime lastWeek = now.addDays(-7);

    m_data = QJsonObject{
        {"exercises", QJsonArray{
                          QJsonObject{
                              {"name", "Bench Press"},
                              {"muscleGroup", "Chest"},
                              {"currentValue", 75.0},
                              {"unit", "kg"},
                              {"repetitions", 8},
                              {"lastUpdated", now.toString(Qt::ISODate)},
                              {"history", QJsonArray{
                                              QJsonObject{
                                                  {"timestamp", yesterday.toString(Qt::ISODate)},
                                                  {"value", 70.0},
                                                  {"unit", "kg"},
                                                  {"repetitions", 8}
                                              },
                                              QJsonObject{
                                                  {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                  {"value", 65.0},
                                                  {"unit", "kg"},
                                                  {"repetitions", 10}
                                              }
                                          }}
                          },
                          QJsonObject{
                              {"name", "Squat"},
                              {"muscleGroup", "Legs"},
                              {"currentValue", 110.0},
                              {"unit", "kg"},
                              {"repetitions", 5},
                              {"lastUpdated", now.toString(Qt::ISODate)},
                              {"history", QJsonArray{
                                              QJsonObject{
                                                  {"timestamp", yesterday.toString(Qt::ISODate)},
                                                  {"value", 100.0},
                                                  {"unit", "kg"},
                                                  {"repetitions", 6}
                                              }
                                          }}
                          },
                          QJsonObject{
                              {"name", "Pull-up"},
                              {"muscleGroup", "Back"},
                              {"currentValue", 8.0},
                              {"unit", "reps"},
                              {"repetitions", 3},
                              {"lastUpdated", now.toString(Qt::ISODate)},
                              {"history", QJsonArray{
                                              QJsonObject{
                                                  {"timestamp", now.toString(Qt::ISODate)},
                                                  {"value", 8.0},
                                                  {"unit", "reps"},
                                                  {"repetitions", 3}
                                              }
                                          }}
                          }
                      }}
    };
}
