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

    QJsonArray history = exercise["history"].toArray();
    history.prepend(QJsonObject{
        {"timestamp", exercise["lastUpdated"].toString()},
        {"value", exercise["currentValue"].toDouble()},
        {"unit", exercise["unit"].toString()},
        {"sets", exercise["sets"].toInt()},
        {"repetitions", exercise["repetitions"].toInt()}
    });

    exercise["currentValue"] = value;
    exercise["unit"] = unit;
    exercise["sets"] = sets;
    exercise["repetitions"] = reps;
    exercise["lastUpdated"] = now.toString(Qt::ISODate);
    exercise["history"] = history;

    exercises[name] = exercise;
    m_data["exercises"] = exercises;
    save();
    emit dataChanged();
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

    QJsonObject exercises;

    // PECHO (Ejercicios con peso)
    exercises["Bench Press"] = QJsonObject{
        {"muscleGroup", "Pecho"},
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
                        }
                    }}
    };

    exercises["Incline Bench Press"] = QJsonObject{
        {"muscleGroup", "Pecho"},
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
                        }
                    }}
    };

    // PIERNAS (Ejercicios con peso)
    exercises["Squat"] = QJsonObject{
        {"muscleGroup", "Piernas"},
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
        {"muscleGroup", "Piernas"},
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
                            {"repetitions", 12},
                            {"sets", 3}
                        }
                    }}
    };

    // ESPALDA (Ejercicios con peso o repeticiones)
    exercises["Deadlift"] = QJsonObject{
        {"muscleGroup", "Espalda"},
        {"currentValue", 140.0},
        {"unit", "kg"},
        {"repetitions", 5},
        {"sets", 3},
        {"lastUpdated", now.toString(Qt::ISODate)},
        {"history", QJsonArray{
                        QJsonObject{
                            {"timestamp", now.toString(Qt::ISODate)},
                            {"value", 140.0},
                            {"unit", "kg"},
                            {"repetitions", 5},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", yesterday.toString(Qt::ISODate)},
                            {"value", 135.0},
                            {"unit", "kg"},
                            {"repetitions", 5},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                            {"value", 130.0},
                            {"unit", "kg"},
                            {"repetitions", 5},
                            {"sets", 3}
                        },
                        QJsonObject{
                            {"timestamp", lastMonth.toString(Qt::ISODate)},
                            {"value", 120.0},
                            {"unit", "kg"},
                            {"repetitions", 6},
                            {"sets", 3}
                        }
                    }}
    };

    // Pull-up es ejercicio basado en repeticiones (sin peso)
    exercises["Pull-up"] = QJsonObject{
        {"muscleGroup", "Espalda"},
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
        {"muscleGroup", "Espalda"},
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
        {"muscleGroup", "Hombros"},
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
        {"muscleGroup", "Hombros"},
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
        {"muscleGroup", "Brazos"},
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
        {"muscleGroup", "Brazos"},
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
                            {"repetitions", 15},
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
                            {"repetitions", 20},
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
                            {"repetitions", 15},
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
