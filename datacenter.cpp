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
                loadData();
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

    // Función auxiliar para crear y ordenar el historial
    auto createAndSortHistory = [](std::initializer_list<QJsonObject> records) -> QJsonArray {
        QList<QJsonObject> historyList;
        for (const auto& record : records) {
            historyList.append(record);
        }

        // Ordenar de más antiguo a más reciente
        std::sort(historyList.begin(), historyList.end(), [](const QJsonObject &a, const QJsonObject &b) {
            QDateTime dateA = QDateTime::fromString(a["timestamp"].toString(), Qt::ISODate);
            QDateTime dateB = QDateTime::fromString(b["timestamp"].toString(), Qt::ISODate);
            return dateA < dateB;
        });

        QJsonArray sortedHistory;
        for (const auto& record : historyList) {
            sortedHistory.append(record);
        }
        return sortedHistory;
    };

    // Función auxiliar para crear un ejercicio
    auto createExercise = [](const QString& muscleGroup, const QJsonArray& history) -> QJsonObject {
        QJsonObject exercise;
        exercise["muscleGroup"] = muscleGroup;

        if (history.isEmpty()) {
            exercise["currentValue"] = 0;
            exercise["repetitions"] = 0;
            exercise["sets"] = 0;
            exercise["lastUpdated"] = "";
            exercise["unit"] = "-";
        } else {
            QJsonObject lastRecord = history.last().toObject();
            exercise["currentValue"] = lastRecord["value"].toDouble();
            exercise["unit"] = lastRecord["unit"].toString();
            exercise["repetitions"] = lastRecord["repetitions"].toInt();
            exercise["sets"] = lastRecord["sets"].toInt();
            exercise["lastUpdated"] = lastRecord["timestamp"].toString();
        }

        exercise["history"] = history;
        return exercise;
    };

    // PECHO (Ejercicios con peso)
    exercises["Bench Press"] = createExercise("Chest", createAndSortHistory({
                                                           {
                                                               {"timestamp", sixMonthAgo.toString(Qt::ISODate)},
                                                               {"value", 55.0},
                                                               {"unit", "lb"},
                                                               {"repetitions", 10},
                                                               {"sets", 3}
                                                           },
                                                           {
                                                               {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                               {"value", 65.0},
                                                               {"unit", "lb"},
                                                               {"repetitions", 10},
                                                               {"sets", 3}
                                                           },
                                                           {
                                                               {"timestamp", yesterday.toString(Qt::ISODate)},
                                                               {"value", 70.0},
                                                               {"unit", "lb"},
                                                               {"repetitions", 8},
                                                               {"sets", 3}
                                                           }
                                                       }));

    exercises["Incline Bench Press"] = createExercise("Chest", createAndSortHistory({
                                                                   {
                                                                       {"timestamp", threeYearsAgo.toString(Qt::ISODate)},
                                                                       {"value", 50.0},
                                                                       {"unit", "kg"},
                                                                       {"repetitions", 10},
                                                                       {"sets", 3}
                                                                   },
                                                                   {
                                                                       {"timestamp", oneYearAgo.toString(Qt::ISODate)},
                                                                       {"value", 40.0},
                                                                       {"unit", "kg"},
                                                                       {"repetitions", 10},
                                                                       {"sets", 3}
                                                                   },
                                                                   {
                                                                       {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                                       {"value", 55.0},
                                                                       {"unit", "kg"},
                                                                       {"repetitions", 10},
                                                                       {"sets", 3}
                                                                   },
                                                                   {
                                                                       {"timestamp", yesterday.toString(Qt::ISODate)},
                                                                       {"value", 60.0},
                                                                       {"unit", "kg"},
                                                                       {"repetitions", 10},
                                                                       {"sets", 3}
                                                                   }
                                                               }));

    // PIERNAS (Ejercicios con peso)
    exercises["Squat"] = createExercise("Legs", createAndSortHistory({
                                                    {
                                                        {"timestamp", yesterday.toString(Qt::ISODate)},
                                                        {"value", 100.0},
                                                        {"unit", "kg"},
                                                        {"repetitions", 6},
                                                        {"sets", 3}
                                                    }
                                                }));

    exercises["Lunges"] = createExercise("Legs", createAndSortHistory({
                                                     {
                                                         {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                         {"value", 45.0},
                                                         {"unit", "kg"},
                                                         {"repetitions", 15},
                                                         {"sets", 3}
                                                     },
                                                     {
                                                         {"timestamp", yesterday.toString(Qt::ISODate)},
                                                         {"value", 48.0},
                                                         {"unit", "kg"},
                                                         {"repetitions", 12},
                                                         {"sets", 3}
                                                     }
                                                 }));

    // ESPALDA (Ejercicios con peso o repeticiones)
    QJsonArray deadliftHistory;
    for (int i = 0; i <= 59; ++i) { // Nota: Ahora en orden cronológico
        QDateTime entryTime = now.addDays(-(59 - i)); // Más antiguo primero
        double value = 80 + i; // Comienza en 80 kg y aumenta
        int repetitions = (i >= 55) ? 6 : 5; // Últimos 5 registros con 6 reps
        int sets = 3;

        deadliftHistory.append(QJsonObject{
            {"timestamp", entryTime.toString(Qt::ISODate)},
            {"value", value},
            {"unit", "kg"},
            {"repetitions", repetitions},
            {"sets", sets}
        });
    }
    exercises["Deadlift"] = createExercise("Back", deadliftHistory);

    // Pull-up es ejercicio basado en repeticiones (sin peso)
    exercises["Pull-up"] = createExercise("Back", createAndSortHistory({
                                                      {
                                                          {"timestamp", lastMonth.toString(Qt::ISODate)},
                                                          {"value", 0},
                                                          {"unit", "-"},
                                                          {"repetitions", 6},
                                                          {"sets", 3}
                                                      },
                                                      {
                                                          {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                          {"value", 0},
                                                          {"unit", "-"},
                                                          {"repetitions", 5},
                                                          {"sets", 3}
                                                      },
                                                      {
                                                          {"timestamp", yesterday.toString(Qt::ISODate)},
                                                          {"value", 0},
                                                          {"unit", "-"},
                                                          {"repetitions", 4},
                                                          {"sets", 3}
                                                      },
                                                      {
                                                          {"timestamp", now.toString(Qt::ISODate)},
                                                          {"value", 0},
                                                          {"unit", "-"},
                                                          {"repetitions", 3},
                                                          {"sets", 3}
                                                      }
                                                  }));

    exercises["Bent-over Row"] = createExercise("Back", createAndSortHistory({
                                                            {
                                                                {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                                {"value", 60.0},
                                                                {"unit", "lb"},
                                                                {"repetitions", 10},
                                                                {"sets", 3}
                                                            },
                                                            {
                                                                {"timestamp", yesterday.toString(Qt::ISODate)},
                                                                {"value", 65.0},
                                                                {"unit", "lb"},
                                                                {"repetitions", 8},
                                                                {"sets", 3}
                                                            }
                                                        }));

    // HOMBROS (Ejercicios con peso)
    exercises["Overhead Press"] = createExercise("Shouders", createAndSortHistory({
                                                                 {
                                                                     {"timestamp", lastMonth.toString(Qt::ISODate)},
                                                                     {"value", 40.0},
                                                                     {"unit", "kg"},
                                                                     {"repetitions", 8},
                                                                     {"sets", 3}
                                                                 },
                                                                 {
                                                                     {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                                     {"value", 45.0},
                                                                     {"unit", "kg"},
                                                                     {"repetitions", 7},
                                                                     {"sets", 3}
                                                                 },
                                                                 {
                                                                     {"timestamp", yesterday.toString(Qt::ISODate)},
                                                                     {"value", 48.0},
                                                                     {"unit", "kg"},
                                                                     {"repetitions", 6},
                                                                     {"sets", 3}
                                                                 },
                                                                 {
                                                                     {"timestamp", now.toString(Qt::ISODate)},
                                                                     {"value", 50.0},
                                                                     {"unit", "kg"},
                                                                     {"repetitions", 6},
                                                                     {"sets", 3}
                                                                 }
                                                             }));

    exercises["Lateral Raise"] = createExercise("Shouders", createAndSortHistory({
                                                                {
                                                                    {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                                    {"value", 13.0},
                                                                    {"unit", "kg"},
                                                                    {"repetitions", 12},
                                                                    {"sets", 3}
                                                                },
                                                                {
                                                                    {"timestamp", yesterday.toString(Qt::ISODate)},
                                                                    {"value", 14.0},
                                                                    {"unit", "kg"},
                                                                    {"repetitions", 12},
                                                                    {"sets", 3}
                                                                }
                                                            }));

    // BRAZOS (Ejercicios con peso)
    exercises["Bicep Curl"] = createExercise("Arms", createAndSortHistory({
                                                         {
                                                             {"timestamp", lastMonth.toString(Qt::ISODate)},
                                                             {"value", 9.0},
                                                             {"unit", "kg"},
                                                             {"repetitions", 15},
                                                             {"sets", 3}
                                                         },
                                                         {
                                                             {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                             {"value", 10.0},
                                                             {"unit", "kg"},
                                                             {"repetitions", 15},
                                                             {"sets", 3}
                                                         },
                                                         {
                                                             {"timestamp", yesterday.toString(Qt::ISODate)},
                                                             {"value", 11.0},
                                                             {"unit", "kg"},
                                                             {"repetitions", 12},
                                                             {"sets", 3}
                                                         },
                                                         {
                                                             {"timestamp", now.toString(Qt::ISODate)},
                                                             {"value", 12.0},
                                                             {"unit", "kg"},
                                                             {"repetitions", 10},
                                                             {"sets", 3}
                                                         }
                                                     }));

    exercises["Tricep Extension"] = createExercise("Arms", createAndSortHistory({
                                                               {
                                                                   {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                                   {"value", 16.0},
                                                                   {"unit", "kg"},
                                                                   {"repetitions", 10},
                                                                   {"sets", 3}
                                                               },
                                                               {
                                                                   {"timestamp", yesterday.toString(Qt::ISODate)},
                                                                   {"value", 18.0},
                                                                   {"unit", "kg"},
                                                                   {"repetitions", 12},
                                                                   {"sets", 3}
                                                               }
                                                           }));

    // CORE (Ejercicios basados en repeticiones: peso 0, unidad "-")
    exercises["Plank"] = createExercise("Core", createAndSortHistory({
                                                    {
                                                        {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                        {"value", 0},
                                                        {"unit", "-"},
                                                        {"repetitions", 1},
                                                        {"sets", 3}
                                                    },
                                                    {
                                                        {"timestamp", yesterday.toString(Qt::ISODate)},
                                                        {"value", 0},
                                                        {"unit", "-"},
                                                        {"repetitions", 1},
                                                        {"sets", 3}
                                                    }
                                                }));

    exercises["Russian Twist"] = createExercise("Core", createAndSortHistory({
                                                            {
                                                                {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                                {"value", 0},
                                                                {"unit", "-"},
                                                                {"repetitions", 15},
                                                                {"sets", 3}
                                                            },
                                                            {
                                                                {"timestamp", yesterday.toString(Qt::ISODate)},
                                                                {"value", 0},
                                                                {"unit", "-"},
                                                                {"repetitions", 12},
                                                                {"sets", 3}
                                                            }
                                                        }));

    exercises["Crunch"] = createExercise("Core", createAndSortHistory({
                                                     {
                                                         {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                         {"value", 0},
                                                         {"unit", "-"},
                                                         {"repetitions", 25},
                                                         {"sets", 3}
                                                     },
                                                     {
                                                         {"timestamp", yesterday.toString(Qt::ISODate)},
                                                         {"value", 0},
                                                         {"unit", "-"},
                                                         {"repetitions", 20},
                                                         {"sets", 3}
                                                     }
                                                 }));

    exercises["Leg Raise"] = createExercise("Core", createAndSortHistory({
                                                        {
                                                            {"timestamp", lastWeek.toString(Qt::ISODate)},
                                                            {"value", 0},
                                                            {"unit", "-"},
                                                            {"repetitions", 16},
                                                            {"sets", 3}
                                                        },
                                                        {
                                                            {"timestamp", yesterday.toString(Qt::ISODate)},
                                                            {"value", 0},
                                                            {"unit", "-"},
                                                            {"repetitions", 15},
                                                            {"sets", 3}
                                                        }
                                                    }));

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
