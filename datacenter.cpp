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
                loadEmptyData();
            } else {
                loadData();
            }
        } else {
            loadEmptyData();
        }
    } else {
        loadEmptyData();
    }

    save(); // Guardar por si hubo correcciones
    qDebug() << "Datos cargados:\n" << QJsonDocument(m_data).toJson(QJsonDocument::Indented);
    emit dataChanged();
}

void DataCenter::loadData() {
    QJsonObject exercises = m_data["exercises"].toObject();
    bool modified = false;

    // Usar iteradores tradicionales para evitar el warning
    const QStringList keys = exercises.keys();
    for (auto it = keys.constBegin(); it != keys.constEnd(); ++it) {
        const QString& key = *it;
        QJsonObject exercise = exercises[key].toObject();
        QJsonArray history = exercise["history"].toArray();

        if (!history.isEmpty()) {
            // Convertir a lista para ordenar (usando iteradores)
            QList<QJsonObject> historyList;
            for (auto histIt = history.constBegin(); histIt != history.constEnd(); ++histIt) {
                historyList.append(histIt->toObject());
            }

            // Ordenar cronológicamente (más antiguo primero)
            std::sort(historyList.begin(), historyList.end(), [](const QJsonObject &a, const QJsonObject &b) {
                QDateTime dateA = QDateTime::fromString(a["timestamp"].toString(), Qt::ISODate);
                QDateTime dateB = QDateTime::fromString(b["timestamp"].toString(), Qt::ISODate);
                return dateA < dateB;
            });

            // Convertir de vuelta a QJsonArray (usando iteradores)
            QJsonArray sortedHistory;
            for (auto listIt = historyList.constBegin(); listIt != historyList.constEnd(); ++listIt) {
                sortedHistory.append(*listIt);
            }

            // Obtener el último registro (más reciente)
            QJsonObject lastRecord = sortedHistory.last().toObject();
            qDebug() << "loadData() - Actualizando ejercicio" << key
                     << "con último registro de:" << lastRecord["timestamp"].toString();

            // Actualizar valores actuales
            exercise["currentValue"] = lastRecord["value"].toDouble();
            exercise["unit"] = lastRecord["unit"].toString();
            exercise["sets"] = lastRecord["sets"].toInt();
            exercise["repetitions"] = lastRecord["repetitions"].toInt();
            exercise["lastUpdated"] = lastRecord["timestamp"].toString();
            exercise["history"] = sortedHistory;

            exercises[key] = exercise;
            modified = true;
        } else {
            qDebug() << "loadData() Ejercicio" << key << "sin historial, estableciendo valores por defecto";
            // Valores por defecto
            exercise["currentValue"] = 0;
            exercise["repetitions"] = 0;
            exercise["sets"] = 0;
            exercise["lastUpdated"] = "";
            exercise["unit"] = "-";

            exercises[key] = exercise;
            modified = true;
        }
    }

    if (modified) {
        m_data["exercises"] = exercises;
        qDebug() << "ANDRESS 4 - Datos modificados y guardados";
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
    bool onlyExerciseName = value == 0 && sets == 0 && reps == 0;

    qDebug() << "➡️ addExercise() llamado con:"
    << "\n  name:" << name
    << "\n  muscleGroup:" << muscleGroup
    << "\n  value:" << value
    << "\n  unit:" << unit
    << "\n  sets:" << sets
    << "\n  reps:" << reps
    << "\n  timestamp:" << now.toString(Qt::ISODate)
    << "\n  onlyExerciseName:" << onlyExerciseName;

    QJsonObject newExercise {
        {"muscleGroup", muscleGroup},
        {"currentValue", value},
        {"unit", unit},
        {"sets", sets},
        {"repetitions", reps},
        {"lastUpdated", now.toString(Qt::ISODate)},
            {"history", onlyExerciseName ? QJsonArray{} : QJsonArray{QJsonObject{
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

    // Obtener historial existente y añadir nuevo registro
    QJsonArray history = exercise["history"].toArray();
    history.append(newRecord);

    // Ordenar historial por fecha (más antiguo primero)
    QList<QJsonObject> historyList;

    // Usando iteradores tradicionales para evitar el warning
    for (auto it = history.begin(); it != history.end(); ++it) {
        historyList.append(it->toObject());
    }

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

    // Actualizar ejercicio con los valores del último registro del historial
    QJsonObject lastRecord = sortedHistory.last().toObject();
    exercise["currentValue"] = lastRecord["value"].toDouble();
    exercise["unit"] = lastRecord["unit"].toString();
    exercise["sets"] = lastRecord["sets"].toInt();
    exercise["repetitions"] = lastRecord["repetitions"].toInt();
    exercise["lastUpdated"] = lastRecord["timestamp"].toString();
    exercise["history"] = sortedHistory;

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

void DataCenter::removeHistoryEntry(const QString &exerciseName, int index) {
    QJsonObject exercises = m_data["exercises"].toObject();
    if (!exercises.contains(exerciseName)) return;

    QJsonObject exercise = exercises[exerciseName].toObject();
    QJsonArray history = exercise["history"].toArray();

    // Primero ordenamos el historial usando iteradores tradicionales
    QList<QJsonObject> historyList;
    for (auto it = history.constBegin(); it != history.constEnd(); ++it) {
        historyList.append(it->toObject());
    }

    std::sort(historyList.begin(), historyList.end(), [](const QJsonObject &a, const QJsonObject &b) {
        QDateTime dateA = QDateTime::fromString(a["timestamp"].toString(), Qt::ISODate);
        QDateTime dateB = QDateTime::fromString(b["timestamp"].toString(), Qt::ISODate);
        return dateA < dateB;
    });

    // Verificamos que el índice sea válido después de ordenar
    if (index < 0 || index >= historyList.size()) return;

    const QString removedTimestamp = historyList[index]["timestamp"].toString();
    historyList.removeAt(index);

    // Convertimos de vuelta a QJsonArray usando iteradores
    QJsonArray sortedHistory;
    for (auto it = historyList.constBegin(); it != historyList.constEnd(); ++it) {
        sortedHistory.append(*it);
    }

    exercise["history"] = sortedHistory;

    // Actualizar currentValue si era el último registro
    if (sortedHistory.isEmpty()) {
        exercise["currentValue"] = 0;
        exercise["repetitions"] = 0;
        exercise["sets"] = 0;
        exercise["lastUpdated"] = "";
        exercise["unit"] = "-";

        qDebug() << "ℹ️ History is empty. Resetting exercise:"
                 << "\n  currentValue: 0"
                 << "\n  repetitions: 0"
                 << "\n  sets: 0"
                 << "\n  lastUpdated: (empty)"
                 << "\n  unit: -";
    } else {
        // Obtenemos el último registro (más reciente)
        const QJsonObject lastEntry = sortedHistory.last().toObject();
        const QString newestTimestamp = lastEntry["timestamp"].toString();
        const QString lastUpdated = exercise["lastUpdated"].toString();

        qDebug() << "🧾 Last updated timestamp:" << lastUpdated
                 << "\n🗑️ Removed entry timestamp:" << removedTimestamp
                 << "\n🆕 Newest timestamp:" << newestTimestamp;

        // Si el registro eliminado era el más reciente o el último actualizado
        if (lastUpdated == removedTimestamp || newestTimestamp == removedTimestamp) {
            exercise["currentValue"] = lastEntry["value"].toDouble();
            exercise["unit"] = lastEntry["unit"].toString();
            exercise["repetitions"] = lastEntry["repetitions"].toInt();
            exercise["sets"] = lastEntry["sets"].toInt();
            exercise["lastUpdated"] = newestTimestamp;

            qDebug() << "🔄 Updated exercise with new last entry:"
                     << "\n  currentValue:" << lastEntry["value"].toDouble()
                     << "\n  unit:" << lastEntry["unit"].toString()
                     << "\n  repetitions:" << lastEntry["repetitions"].toInt()
                     << "\n  sets:" << lastEntry["sets"].toInt()
                     << "\n  lastUpdated:" << newestTimestamp;
        } else {
            qDebug() << "✅ Removed entry was not the last updated. No update needed.";
        }
    }

    exercises[exerciseName] = exercise;
    m_data["exercises"] = exercises;

    save();
    emit dataChanged();
}

void DataCenter::reloadSampleData() {
    qDebug() << "reloadSampleData()";
    QFile file(getFilePath());
    if (file.exists()) {
        if (file.remove()) {
            qDebug("Archivo eliminado correctamente, inicializando estructura vacía...");
        }
    }
    loadSampleData();
    save();
    emit dataChanged();
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

    loadEmptyData();
}

QString DataCenter::getFilePath() const {
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/exercises.json";
}

void DataCenter::loadTestData() {
    QDateTime now = QDateTime::currentDateTime();

    // Estructura para organizar los ejercicios por grupo muscular
    QMap<QString, QList<QString>> muscleGroups = {
        {"Chest", {"Bench Press", "Incline Bench Press"}},
        {"Legs", {"Squat", "Lunges"}},
        {"Back", {"Deadlift", "Pull-up", "Bent-over Row"}},
        {"Shoulders", {"Overhead Press", "Lateral Raise"}},
        {"Arms", {"Bicep Curl", "Tricep Extension"}},
        {"Core", {"Plank", "Russian Twist", "Crunch", "Leg Raise"}}
    };

    // Configuración base para cada tipo de ejercicio
    QMap<QString, QMap<QString, QVariant>> exerciseConfigs = {
        {"Bench Press", {{"unit", "lb"}, {"initial", 55.0}, {"increment", 5.0}}},
        {"Incline Bench Press", {{"unit", "kg"}, {"initial", 50.0}, {"increment", 5.0}}},
        {"Squat", {{"unit", "kg"}, {"initial", 100.0}, {"increment", 2.5}}},
        {"Lunges", {{"unit", "kg"}, {"initial", 45.0}, {"increment", 1.0}}},
        {"Deadlift", {{"unit", "kg"}, {"initial", 80.0}, {"increment", 1.0}}},
        {"Pull-up", {{"unit", "-"}, {"initial", 0.0}, {"increment", 0.0}}},
        {"Bent-over Row", {{"unit", "lb"}, {"initial", 60.0}, {"increment", 5.0}}},
        {"Overhead Press", {{"unit", "kg"}, {"initial", 40.0}, {"increment", 2.0}}},
        {"Lateral Raise", {{"unit", "kg"}, {"initial", 13.0}, {"increment", 1.0}}},
        {"Bicep Curl", {{"unit", "kg"}, {"initial", 9.0}, {"increment", 1.0}}},
        {"Tricep Extension", {{"unit", "kg"}, {"initial", 16.0}, {"increment", 2.0}}},
        {"Plank", {{"unit", "-"}, {"initial", 0.0}, {"increment", 0.0}}},
        {"Russian Twist", {{"unit", "-"}, {"initial", 0.0}, {"increment", 0.0}}},
        {"Crunch", {{"unit", "-"}, {"initial", 0.0}, {"increment", 0.0}}},
        {"Leg Raise", {{"unit", "-"}, {"initial", 0.0}, {"increment", 0.0}}}
    };

    QJsonObject exercises;

    // Función para generar historial de progresión
    auto generateHistory = [&](const QString& name, int daysBack, int entryCount) {
        QJsonArray history;
        QMap<QString, QVariant> config = exerciseConfigs[name];
        double currentValue = config["initial"].toDouble();
        double increment = config["increment"].toDouble();

        for (int i = 0; i < entryCount; ++i) {
            QDateTime timestamp = now.addDays(-(daysBack - i));

            QJsonObject record{
                {"timestamp", timestamp.toString(Qt::ISODate)},
                {"value", currentValue},
                {"unit", config["unit"].toString()},
                {"repetitions", (name.contains("Press") || name == "Deadlift") ? 6 :
                                    (name == "Pull-up") ? 5 :
                                    (name == "Plank") ? 1 : 12},
                {"sets", 3}
            };

            history.append(record);

            // Solo incrementar si no es un ejercicio sin peso
            if (increment > 0) {
                currentValue += increment;

                // Ajustar incremento para los últimos registros
                if (i > entryCount - 5) {
                    currentValue += (increment * 0.5);
                }
            }
        }

        return history;
    };

    // Generar todos los ejercicios
    for (const QString& muscleGroup : muscleGroups.keys()) {
        for (const QString& exerciseName : muscleGroups[muscleGroup]) {
            int daysBack = (exerciseName == "Deadlift") ? 60 :
                               (exerciseName.contains("Press")) ? 180 : 30;
            int entryCount = (exerciseName == "Deadlift") ? 60 :
                                 (exerciseName.contains("Press")) ? 12 : 6;

            QJsonArray history = generateHistory(exerciseName, daysBack, entryCount);

            // Crear objeto de ejercicio
            QJsonObject exercise;
            exercise["muscleGroup"] = muscleGroup;

            if (!history.isEmpty()) {
                QJsonObject lastRecord = history.last().toObject();
                exercise["currentValue"] = lastRecord["value"].toDouble();
                exercise["unit"] = lastRecord["unit"].toString();
                exercise["repetitions"] = lastRecord["repetitions"].toInt();
                exercise["sets"] = lastRecord["sets"].toInt();
                exercise["lastUpdated"] = lastRecord["timestamp"].toString();
            } else {
                exercise["currentValue"] = 0;
                exercise["unit"] = "-";
                exercise["repetitions"] = 0;
                exercise["sets"] = 0;
                exercise["lastUpdated"] = "";
            }

            exercise["history"] = history;
            exercises[exerciseName] = exercise;
        }
    }

    m_data = QJsonObject{{"exercises", exercises}};
}

void DataCenter::loadEmptyData() {
    // Crear estructura vacía
    m_data = QJsonObject{
        {"exercises", QJsonObject{}}
    };

    save();
    emit dataChanged();
    qDebug() << "Estructura vacía lista para ingresar ejercicios manualmente.";
}

void DataCenter::loadSampleData() {
    // Lista organizada de ejercicios por grupo muscular
    QMap<QString, QList<QString>> muscleGroups = {
        {"Chest", {"Bench Press", "Incline Bench Press", "Chest Fly"}},
        {"Legs", {"Squat", "Lunges", "Leg Press", "Deadlift"}},
        {"Back", {"Lat Pulldown", "Bent-over Row", "Seated Row", "Pull-up"}},
        {"Shoulders", {"Overhead Press", "Lateral Raise", "Front Raise"}},
        {"Arms", {"Bicep Curl", "Tricep Extension", "Hammer Curl"}},
        {"Core", {"Plank", "Russian Twist", "Crunch", "Leg Raise", "Hanging Knee Raise"}}
    };

    QJsonObject exercises;

    // Crear cada ejercicio con estructura vacía
    for (const QString& muscleGroup : muscleGroups.keys()) {
        for (const QString& exerciseName : muscleGroups[muscleGroup]) {
            QJsonObject exercise;
            exercise["muscleGroup"] = muscleGroup;
            exercise["currentValue"] = 0;         // Valor inicial 0
            exercise["unit"] = "-";               // Unidad no especificada
            exercise["sets"] = 0;                 // 0 series por defecto
            exercise["repetitions"] = 0;          // 0 repeticiones por defecto
            exercise["lastUpdated"] = "";         // Fecha vacía
            exercise["history"] = QJsonArray();   // Array de historial vacío

            exercises[exerciseName] = exercise;
        }
    }

    // Crear la estructura principal de datos
    m_data = QJsonObject{
        {"exercises", exercises},
        {"lastSync", QDateTime::currentDateTime().toString(Qt::ISODate)},
        {"appVersion", "1.0.0"}
    };
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
