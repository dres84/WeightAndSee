#include "datacenter.h"
#include <QFile>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
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

    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        file.close();

        if (!doc.isNull() && doc.isObject()) {
            m_data = doc.object();

            if (!m_data.contains("exercises") || !m_data["exercises"].isObject()) {
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
    QJsonObject exercises = m_data["exercises"].toObject();
    bool modified = false;

    for (const QString& key : exercises.keys()) {
        QJsonObject exercise = exercises[key].toObject();
        QJsonArray history = exercise["history"].toArray();

        if (history.isEmpty()) {
            QJsonObject record;
            record["timestamp"] = exercise["lastUpdated"].toString();
            record["value"] = exercise["currentValue"].toDouble();
            record["unit"] = exercise["unit"].toString();
            record["sets"] = exercise["sets"].toInt();
            record["repetitions"] = exercise["repetitions"].toInt();

            history.append(record);
            exercise["history"] = history;
            exercises[key] = exercise;
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
                             double value, const QString& unit, int sets, int reps) {
    QJsonObject exercises = m_data["exercises"].toObject();
    QDateTime now = QDateTime::currentDateTime();

    QJsonObject newExercise {
        {"muscleGroup", muscleGroup},
        {"currentValue", value},
        {"unit", unit},
        {"sets", sets},
        {"repetitions", reps},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{QJsonObject{
                        {"timestamp", now.toString(Qt::ISODate)},
                        {"value", value},
                        {"unit", unit},
                        {"sets", sets},
                        {"repetitions", reps}
                    }}}
    };

    exercises[name] = newExercise;
    m_data["exercises"] = exercises;
    save();
    emit dataChanged();
}

void DataCenter::updateExercise(const QString& name, double value, const QString& unit, int sets, int reps) {
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(name)) return;

    QJsonObject exercise = exercises[name].toObject();
    QDateTime now = QDateTime::currentDateTime();

    // Crear nuevo registro
    QJsonObject newRecord {
        {"timestamp", now.toString(Qt::ISODate)},
        {"value", value},
        {"unit", unit},
        {"sets", sets},
        {"repetitions", reps}
    };

    // Obtener historial existente
    QJsonArray history = exercise["history"].toArray();

    // Añadir nuevo registro
    history.append(newRecord);

    // Convertir a lista para ordenar
    QList<QJsonObject> historyList;
    for (const QJsonValue& val : history) {
        historyList.append(val.toObject());
    }

    // Ordenar por fecha (más antiguo primero)
    std::sort(historyList.begin(), historyList.end(), [](const QJsonObject &a, const QJsonObject &b) {
        QDateTime dateA = QDateTime::fromString(a["timestamp"].toString(), Qt::ISODate);
        QDateTime dateB = QDateTime::fromString(b["timestamp"].toString(), Qt::ISODate);
        return dateA < dateB;
    });

    // Convertir de vuelta a QJsonArray
    QJsonArray sortedHistory;
    for (const QJsonObject& obj : historyList) {
        sortedHistory.append(obj);
    }

    // Actualizar ejercicio
    exercise["currentValue"] = value;
    exercise["unit"] = unit;
    exercise["sets"] = sets;
    exercise["repetitions"] = reps;
    exercise["lastUpdated"] = now.toString(Qt::ISODate);
    exercise["history"] = sortedHistory;

    exercises[name] = exercise;
    m_data["exercises"] = exercises;

    save();
    emit dataChanged();

    qDebug() << "Ejercicio actualizado:" << name << "| Valor:" << value << unit
             << "| Sets:" << sets << "| Reps:" << reps;
}

void DataCenter::removeExercise(const QString& name) {
    qDebug() << "DataCenter::removeExercise Intentamos eliminar el ejercicio: " << name;
    QJsonObject exercises = m_data["exercises"].toObject();
    if (exercises.contains(name)) {
        exercises.remove(name);
        qDebug() << "DataCenter::removeExercise el elemento " << name << " eliminado correctamente.";
        m_data["exercises"] = exercises;
        save();
        emit dataChanged();
    } else {
        qDebug() << "DataCenter::removeExercise el elemento " << name << " no existe!";
    }
}

void DataCenter::removeHistoryEntry(const QString &exerciseName, int index) {
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return;

    QJsonObject exercise = exercises[exerciseName].toObject();
    QJsonArray history = exercise["history"].toArray();

    if (index < 0 || index >= history.size()) return;

    history.removeAt(index);
    exercise["history"] = history;

    // Actualizar currentValue si era el último registro
    if (history.isEmpty()) {
        exercise["currentValue"] = 0;
        exercise["repetitions"] = 0;
        exercise["sets"] = 0;
        exercise["lastUpdated"] = "";
    } else {
        // Si era el registro actual, actualizar con el nuevo último
        const QString lastUpdated = exercise["lastUpdated"].toString();
        const QString removedTimestamp = history[index].toObject()["timestamp"].toString();

        if (lastUpdated == removedTimestamp) {
            const QJsonObject lastEntry = history.last().toObject();
            exercise["currentValue"] = lastEntry["value"].toDouble();
            exercise["unit"] = lastEntry["unit"].toString();
            exercise["repetitions"] = lastEntry["repetitions"].toInt();
            exercise["sets"] = lastEntry["sets"].toInt();
            exercise["lastUpdated"] = lastEntry["timestamp"].toString();
        }
    }

    exercises[exerciseName] = exercise;
    m_data["exercises"] = exercises;

    save();
    emit dataChanged();
}

void DataCenter::reloadDefaultData() {
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

void DataCenter::deleteAllExercises() {
    QFile file(getFilePath());
    if (file.exists()) {
        if (file.remove()) {
            qDebug("Archivo eliminado correctamente, inicializando estructura vacía...");
        } else {
            qWarning("No se pudo eliminar el archivo");
            return;
        }
    }

    // Crear estructura vacía
    m_data = QJsonObject{
        {"exercises", QJsonObject{}}
    };

    save();
    emit dataChanged();
    qDebug() << "Estructura vacía lista para ingresar ejercicios manualmente.";
}

QString DataCenter::getFilePath() const {
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/exercises.json";
}

void DataCenter::loadDefaultData() {
    QDateTime now = QDateTime::currentDateTime();
    QDateTime yesterday = now.addDays(-1);
    QDateTime lastWeek = now.addDays(-7);
    QDateTime lastMonth = now.addMonths(-1);
    QDateTime sixMonthAgo = now.addMonths(-6);
    QDateTime oneYearAgo = now.addYears(-1);
    QDateTime threeYearsAgo = now.addYears(-3);


    QJsonObject exercises;

    // PECHO (Ejercicios con peso)
    exercises["Bench Press"] = QJsonObject{
        {"muscleGroup", "Chest"},
        {"currentValue", 75.0},
        {"unit", "lb"},
        {"repetitions", 8},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 70.0},
                            {"unit", "lb"},
                            {"repetitions", 8},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 65.0},
                            {"unit", "lb"},
                            {"repetitions", 10},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", sixMonthAgo.toString(Qt::ISODate)},
                            {"value", 55.0},
                            {"unit", "lb"},
                            {"repetitions", 10},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Incline Bench Press"] = QJsonObject{
        {"muscleGroup", "Chest"},
        {"currentValue", 65.0},
        {"unit", "kg"},
        {"repetitions", 10},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 60.0},
                            {"unit", "kg"},
                            {"repetitions", 10},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 55.0},
                            {"unit", "kg"},
                            {"repetitions", 10},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", oneYearAgo.toString(Qt::ISODate)},
                            {"value", 40.0},
                            {"unit", "kg"},
                            {"repetitions", 10},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", threeYearsAgo.toString(Qt::ISODate)},
                            {"value", 50.0},
                            {"unit", "kg"},
                            {"repetitions", 10},
                            {"sets", 3}
                        }
                    }}
    };

    // PIERNAS (Ejercicios con peso)
    exercises["Squat"] = QJsonObject{
        {"muscleGroup", "Legs"},
        {"currentValue", 110.0},
        {"unit", "kg"},
        {"repetitions", 5},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 100.0},
                            {"unit", "kg"},
                            {"repetitions", 6},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Lunges"] = QJsonObject{
        {"muscleGroup", "Legs"},
        {"currentValue", 50.0},
        {"unit", "kg"},
        {"repetitions", 12},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 48.0},
                            {"unit", "kg"},
                            {"repetitions", 12},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 45.0},
                            {"unit", "kg"},
                            {"repetitions", 15},
                            {"sets", 3}
                        }
                    }}
    };

    QJsonArray history;
    for (int i = 59; i >= 0; --i) {
        QDateTime entryTime = now.addDays(-i * 1);  // Cada entrada separada por 1 día
        double value = 139 - i;  // Aumenta 1 kg cada vez
        int repetitions = (i < 5) ? 6 : 5;  // Últimos 5 registros con 6 reps, el resto 5
        int sets = 3;

        history.append(QJsonObject{
            {"timestamp", entryTime.toString(Qt::ISODate)},
            {"value", value},
            {"unit", "kg"},
            {"repetitions", repetitions},
            {"sets", sets}
        });
    }

    // ESPALDA (Ejercicios con peso o repeticiones)
    exercises["Deadlift"] = QJsonObject{
        {"muscleGroup", "Back"},
        {"currentValue", 139.0},
        {"unit", "kg"},
        {"repetitions", 5},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", history}
    };

    // Pull-up es ejercicio basado en repeticiones (sin peso)
    exercises["Pull-up"] = QJsonObject{
        {"muscleGroup", "Back"},
        {"currentValue", 0},
        {"unit", "-"},
        {"repetitions", 3},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", now.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 3},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 4},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 5},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastMonth.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 6},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Bent-over Row"] = QJsonObject{
        {"muscleGroup", "Back"},
        {"currentValue", 70.0},
        {"unit", "lb"},
        {"repetitions", 8},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 65.0},
                            {"unit", "lb"},
                            {"repetitions", 8},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 60.0},
                            {"unit", "lb"},
                            {"repetitions", 10},
                            {"sets", 3}
                        }
                    }}
    };

    // HOMBROS (Ejercicios con peso)
    exercises["Overhead Press"] = QJsonObject{
        {"muscleGroup", "Shouders"},
        {"currentValue", 50.0},
        {"unit", "kg"},
        {"repetitions", 6},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", now.toString(Qt::ISODate)},
                            {"value", 50.0},
                            {"unit", "kg"},
                            {"repetitions", 6},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 48.0},
                            {"unit", "kg"},
                            {"repetitions", 6},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 45.0},
                            {"unit", "kg"},
                            {"repetitions", 7},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastMonth.toString(Qt::ISODate)},
                            {"value", 40.0},
                            {"unit", "kg"},
                            {"repetitions", 8},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Lateral Raise"] = QJsonObject{
        {"muscleGroup", "Shouders"},
        {"currentValue", 15.0},
        {"unit", "kg"},
        {"repetitions", 12},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 14.0},
                            {"unit", "kg"},
                            {"repetitions", 12},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 13.0},
                            {"unit", "kg"},
                            {"repetitions", 12},
                            {"sets", 3}
                        }
                    }}
    };

    // BRAZOS (Ejercicios con peso)
    exercises["Bicep Curl"] = QJsonObject{
        {"muscleGroup", "Arms"},
        {"currentValue", 12.0},
        {"unit", "kg"},
        {"repetitions", 10},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", now.toString(Qt::ISODate)},
                            {"value", 12.0},
                            {"unit", "kg"},
                            {"repetitions", 10},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 11.0},
                            {"unit", "kg"},
                            {"repetitions", 12},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 10.0},
                            {"unit", "kg"},
                            {"repetitions", 15},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastMonth.toString(Qt::ISODate)},
                            {"value", 9.0},
                            {"unit", "kg"},
                            {"repetitions", 15},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Tricep Extension"] = QJsonObject{
        {"muscleGroup", "Arms"},
        {"currentValue", 20.0},
        {"unit", "kg"},
        {"repetitions", 10},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 18.0},
                            {"unit", "kg"},
                            {"repetitions", 12},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 16.0},
                            {"unit", "kg"},
                            {"repetitions", 10},
                            {"sets", 3}
                        }
                    }}
    };

    // CORE (Ejercicios basados en repeticiones: peso 0, unidad "-")
    exercises["Plank"] = QJsonObject{
        {"muscleGroup", "Core"},
        {"currentValue", 0},
        {"unit", "-"},
        {"repetitions", 1},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 1},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 1},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Russian Twist"] = QJsonObject{
        {"muscleGroup", "Core"},
        {"currentValue", 0},
        {"unit", "-"},
        {"repetitions", 15},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 12},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 15},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Crunch"] = QJsonObject{
        {"muscleGroup", "Core"},
        {"currentValue", 0},
        {"unit", "-"},
        {"repetitions", 20},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 20},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 25},
                            {"sets", 3}
                        }
                    }}
    };

    exercises["Leg Raise"] = QJsonObject{
        {"muscleGroup", "Core"},
        {"currentValue", 0},
        {"unit", "-"},
        {"repetitions", 15},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 15},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 0},
                            {"unit", "-"},
                            {"repetitions", 16},
                            {"sets", 3}
                        }
                    }}
    };

    m_data = QJsonObject{{"exercises", exercises}};
}


QString DataCenter::getMuscleGroup(const QString& exerciseName) const
{
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return "";

    return exercises[exerciseName].toObject()["muscleGroup"].toString();
}

double DataCenter::getCurrentValue(const QString& exerciseName) const
{
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return 0.0;

    return exercises[exerciseName].toObject()["currentValue"].toDouble();
}

QString DataCenter::getUnit(const QString& exerciseName) const
{
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return "";

    return exercises[exerciseName].toObject()["unit"].toString();
}

int DataCenter::getRepetitions(const QString& exerciseName) const
{
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return 0;

    return exercises[exerciseName].toObject()["repetitions"].toInt();
}

int DataCenter::getSets(const QString& exerciseName) const
{
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return 0;

    return exercises[exerciseName].toObject()["sets"].toInt();
}

QVariantList DataCenter::getExerciseHistoryDetailed(const QString &exerciseName) const {
    QVariantList historyList;

    if (!m_data.contains("exercises")) return historyList;

    const QJsonObject exercisesObj = m_data["exercises"].toObject();
    if (!exercisesObj.contains(exerciseName)) return historyList;

    const QJsonObject exerciseObj = exercisesObj[exerciseName].toObject();
    const QJsonArray historyArray = exerciseObj["history"].toArray();

    for (const QJsonValueConstRef &entryVal : historyArray) {
        const QJsonObject entry = entryVal.toObject();
        QVariantMap map;
        map["date"] = entry["timestamp"].toString();
        map["weight"] = entry["value"].toDouble();
        map["unit"] = entry["unit"].toString();
        map["sets"] = entry["sets"].toInt();
        map["reps"] = entry["repetitions"].toInt();
        historyList.append(map);
    }

    return historyList;
}

void DataCenter::exportData(const QString& filePath) {
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(m_data).toJson());
        file.close();
        qDebug() << "Datos exportados a:" << filePath;
        emit showMessage(tr("Datos exportados"), tr("Los datos se han guardado en:") + "\n" + filePath);
    } else {
        qWarning() << "No se pudo exportar los datos";
        emit showMessage(tr("Error"), tr("No se pudo guardar el archivo"));
    }
}

void DataCenter::importData(const QUrl &fileUrl) {
    QFile file(fileUrl.toLocalFile());
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        file.close();

        if (!doc.isNull() && doc.isObject()) {
            m_data = doc.object();
            save();
            emit dataChanged();
            emit showMessage(tr("Datos importados"), tr("Los datos se han importado correctamente"));
        } else {
            emit showMessage(tr("Error"), tr("El archivo no contiene datos válidos"));
        }
    } else {
        emit showMessage(tr("Error"), tr("No se pudo leer el archivo"));
    }
}
