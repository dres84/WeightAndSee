#include "ExerciseProvider.h"
#include <QFile>
#include <QTextStream>
#include <QVariantMap>

ExerciseProvider::ExerciseProvider(QObject *parent)
    : QObject(parent)
{
    loadExercisesFromFile();
}

void ExerciseProvider::loadExercisesFromFile() {
    QFile file(":/data/exerciseList.txt");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Error intentando abrir el fichero: " << file.fileName();
        return;
    } else {
        qDebug() << "Fichero: " << file.fileName() << " abierto sin problemas";
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        auto parts = line.split("|");
        if (parts.size() == 2) {
            QString name = parts[0].trimmed();
            QString group = parts[1].trimmed();

            if (!existsExercise(name, group)) {
                QVariantMap exercise;
                exercise["name"] = name;
                exercise["group"] = group;
                m_exercises.append(exercise);
            } else {
                qDebug() << "Ejercicio duplicado ignorado:" << name << "(" << group << ")";
            }
        }
    }

    qDebug() << "La Lista de ejercicios final es : " << m_exercises;
    emit exercisesChanged();
}

bool ExerciseProvider::existsExercise(const QString &name, const QString &group) const {
    for (const QVariant &item : m_exercises) {
        QVariantMap existing = item.toMap();
        QString existingName = existing["name"].toString();
        QString existingGroup = existing["group"].toString();

        if (existingName.compare(name, Qt::CaseInsensitive) == 0 &&
            existingGroup.compare(group, Qt::CaseInsensitive) == 0) {
            return true;
        }
    }
    return false;
}

QVariantList ExerciseProvider::exercises() const {
    return m_exercises;
}
