#include "exercisemodel.h"
#include <algorithm>
#include <qjsonarray.h>
#include <QJsonDocument>

QJsonObject ExerciseModel::Exercise::toJson() const {
    QJsonObject obj;
    obj["name"] = name;
    obj["muscleGroup"] = muscleGroup;
    obj["currentValue"] = currentValue;
    obj["unit"] = unit;
    obj["repetitions"] = repetitions;
    obj["lastUpdated"] = lastUpdated.toString(Qt::ISODate);

    QJsonArray historyArray;
    for (const auto& record : history) {
        historyArray.append(record.toJson());
    }
    obj["history"] = historyArray;

    return obj;
}

ExerciseModel::Exercise ExerciseModel::Exercise::fromJson(const QString& key, const QJsonObject& json) {
    Exercise exercise;
    exercise.name = key; // ← Aquí usamos la clave como nombre
    exercise.muscleGroup = json["muscleGroup"].toString();
    exercise.currentValue = json["currentValue"].toDouble();
    exercise.unit = json["unit"].toString();
    exercise.repetitions = json["repetitions"].toInt();
    exercise.lastUpdated = QDateTime::fromString(json["lastUpdated"].toString(), Qt::ISODate);

    QJsonArray historyArray = json["history"].toArray();
    for (const QJsonValue& value : historyArray) {
        exercise.history.append(HistoryRecord::fromJson(value.toObject()));
    }

    return exercise;
}

QJsonObject ExerciseModel::HistoryRecord::toJson() const {
    QJsonObject obj;
    obj["timestamp"] = timestamp.toString(Qt::ISODate);
    obj["value"] = value;
    obj["unit"] = unit;
    obj["repetitions"] = repetitions;
    return obj;
}

ExerciseModel::HistoryRecord ExerciseModel::HistoryRecord::fromJson(const QJsonObject& json) {
    HistoryRecord record;
    record.timestamp = QDateTime::fromString(json["timestamp"].toString(), Qt::ISODate);
    record.value = json["value"].toDouble();
    record.unit = json["unit"].toString();
    record.repetitions = json["repetitions"].toInt();
    return record;
}

ExerciseModel::ExerciseModel(QObject *parent) : QAbstractListModel(parent) {}

int ExerciseModel::rowCount(const QModelIndex& parent) const {
    Q_UNUSED(parent)
    return m_exercises.count();
}

QVariant ExerciseModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || index.row() >= m_exercises.count())
        return QVariant();

    const Exercise& exercise = m_exercises.at(index.row());

    switch (role) {
    case NameRole: return exercise.name;
    case MuscleGroupRole: return exercise.muscleGroup;
    case CurrentValueRole: return exercise.currentValue;
    case UnitRole: return exercise.unit;
    case RepetitionsRole: return exercise.repetitions;
    case LastUpdatedRole: return exercise.lastUpdated;
    case HistoryRole: {
        QVariantList history;
        for (const auto& record : exercise.history) {
            history.append(QVariantMap{
                {"timestamp", record.timestamp},
                {"value", record.value},
                {"unit", record.unit},
                {"repetitions", record.repetitions}
            });
        }
        return history;
    }
    default: return QVariant();
    }
}

QHash<int, QByteArray> ExerciseModel::roleNames() const {
    return {
        {NameRole, "name"},
        {MuscleGroupRole, "muscleGroup"},
        {CurrentValueRole, "currentValue"},
        {UnitRole, "unit"},
        {RepetitionsRole, "repetitions"},
        {LastUpdatedRole, "lastUpdated"},
        {HistoryRole, "history"}
    };
}

void ExerciseModel::loadFromJson(const QJsonObject& json) {
    beginResetModel();
    m_exercises.clear();

    qDebug() << "Cargando datos en ExerciseModel...";
    qDebug() << "Datos recibidos:" << QJsonDocument(json).toJson(QJsonDocument::Indented);

    QJsonObject exercisesObj = json["exercises"].toObject();
    for (const QString& key : exercisesObj.keys()) {
        const QJsonObject& exerciseData = exercisesObj[key].toObject();
        m_exercises.append(Exercise::fromJson(key, exerciseData));
    }

    endResetModel();

    qDebug() << "Modelo actualizado. Total ejercicios:" << m_exercises.count();
}

QJsonObject ExerciseModel::toJson() const {
    QJsonObject root;
    QJsonObject exercisesObject;
    for (const auto& exercise : m_exercises) {
        exercisesObject[exercise.name] = exercise.toJson();
    }
    root["exercises"] = exercisesObject;

    return root;
}

void ExerciseModel::addExercise(const QString& name, const QString& muscleGroup,
                                double value, const QString& unit, int reps) {
    beginInsertRows(QModelIndex(), rowCount(), rowCount());

    Exercise newExercise;
    newExercise.name = name;
    newExercise.muscleGroup = muscleGroup;
    newExercise.currentValue = value;
    newExercise.unit = unit;
    newExercise.repetitions = reps;
    newExercise.lastUpdated = QDateTime::currentDateTime();

    m_exercises.append(newExercise);
    endInsertRows();
}

void ExerciseModel::updateExercise(int index, double value, int reps) {
    if (index < 0 || index >= m_exercises.count())
        return;

    // Guardar registro actual en historial
    HistoryRecord currentRecord;
    currentRecord.timestamp = m_exercises[index].lastUpdated;
    currentRecord.value = m_exercises[index].currentValue;
    currentRecord.unit = m_exercises[index].unit;
    currentRecord.repetitions = m_exercises[index].repetitions;

    m_exercises[index].history.prepend(currentRecord);

    // Actualizar valores
    m_exercises[index].currentValue = value;
    m_exercises[index].repetitions = reps;
    m_exercises[index].lastUpdated = QDateTime::currentDateTime();

    // Ordenar historial
    std::sort(m_exercises[index].history.begin(), m_exercises[index].history.end(),
              [](const HistoryRecord& a, const HistoryRecord& b) {
                  return a.timestamp > b.timestamp;
              });

    emit dataChanged(createIndex(index, 0), createIndex(index, 0));
}

void ExerciseModel::removeExercise(int index) {
    if (index < 0 || index >= m_exercises.count())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_exercises.removeAt(index);
    endRemoveRows();
}
