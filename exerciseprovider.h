#ifndef EXERCISEPROVIDER_H
#define EXERCISEPROVIDER_H

#include <QObject>
#include <QStringList>

class ExerciseProvider : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList exercises READ exercises NOTIFY exercisesChanged)

public:
    explicit ExerciseProvider(QObject *parent = nullptr);

    QVariantList exercises() const;

signals:
    void exercisesChanged();

private:
    QVariantList m_exercises;
    void loadExercisesFromFile();
    bool existsExercise(const QString &name, const QString &group) const;
};


#endif // EXERCISEPROVIDER_H

