#include "datacenter.h"
#include <QStandardPaths>
#include <QDate>

DataCenter::DataCenter(QObject *parent) : QObject(parent) {
    load();
}

QJsonObject DataCenter::data() const {
    return m_data;
}

void DataCenter::save() {
    QFile file(getFilePath());
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("No se pudo abrir el archivo para escritura");
        return;
    }
    QJsonDocument doc(m_data);
    file.write(doc.toJson());
    file.close();
}

QJsonObject DataCenter::load() {
    QFile file(getFilePath());
    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        QByteArray data = file.readAll();
        file.close();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isNull() && doc.isObject()) {
            m_data = doc.object();
            emit dataChanged();
            return m_data;
        }
    }
    loadDefaultData();
    save();
    emit dataChanged();
    return m_data;
}

void DataCenter::loadDefaultData() {
    m_data = {
        {"exercises", QJsonObject {
                          {"abdominales", QJsonObject{{"part", "core"}, {"unit", "Repeticiones"}, {"selectedWeight", 0}, {"history", QJsonArray()}}},
                          {"sentadillas", QJsonObject{{"part", "tren_inferior"}, {"unit", "Repeticiones"}, {"selectedWeight", 0}, {"history", QJsonArray()}}},
                          {"press_banca", QJsonObject{{"part", "tren_superior"}, {"unit", "Kg."}, {"selectedWeight", 0}, {"history", QJsonArray()}}}
                      }}
    };
}

QString DataCenter::getFilePath() const {
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/data.json";
}

void DataCenter::deleteFile() {
    QFile file(getFilePath());
    if (file.exists()) {
        if (file.remove()) {
            qDebug("Archivo eliminado correctamente, cargamos el valor por defecto");
            load();
        } else {
            qWarning("No se pudo eliminar el archivo");
        }
    } else {
        qWarning("El archivo no existe");
    }
}

void DataCenter::addExercise(const QString &name, const QString &part, const QString &unit) {
    QJsonObject exercises = m_data["exercises"].toObject();

    QJsonObject newExercise;
    newExercise["part"] = part;
    newExercise["unit"] = unit;
    newExercise["selectedWeight"] = 0;
    newExercise["history"] = QJsonArray();

    exercises[name] = newExercise;
    m_data["exercises"] = exercises;

    save();
    emit dataChanged();
}

void DataCenter::deleteExercise(const QString &name) {
    QJsonObject exercises = m_data["exercises"].toObject();

    if (exercises.contains(name)) {
        exercises.remove(name);
        m_data["exercises"] = exercises;
        save();
        emit dataChanged();
    }
}

void DataCenter::updateExerciseWeight(const QString &exerciseName, int newWeight, QString unit) {
    if (m_data["exercises"].toObject().contains(exerciseName)) {
        QJsonObject exercises = m_data["exercises"].toObject();
        QJsonObject exercise = exercises[exerciseName].toObject();
        exercise["selectedWeight"] = newWeight;

        QJsonArray history = exercise["history"].toArray();
        QJsonObject entry;
        entry["date"] = QDate::currentDate().toString(Qt::ISODate);
        entry["value"] = newWeight;
        history.append(entry);
        exercise["unit"] = unit;
        exercise["history"] = history;
        exercises[exerciseName] = exercise;
        m_data["exercises"] = exercises;

        save();
        emit dataChanged();
    }
}

void DataCenter::updateModel()
{
    emit dataChanged();
}

void DataCenter::saveSectionStates(const QJsonObject &sections) {
    m_data["sectionStates"] = sections;
    save();
    emit sectionStatesChanged();
}

QJsonObject DataCenter::loadSectionStates() {
    if (m_data.contains("sectionStates")) {
        return m_data["sectionStates"].toObject();
    }
    // Valores por defecto (todas las secciones expandidas)
    return QJsonObject{
        {"tren_superior", true},
        {"core", true},
        {"tren_inferior", true}
    };
}
