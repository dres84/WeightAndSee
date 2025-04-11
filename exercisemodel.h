#ifndef EXERCISEMODEL_H
#define EXERCISEMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QJsonObject>

class ExerciseModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY modelChanged)

public:
    struct HistoryRecord {
        QDateTime timestamp;
        double value;
        QString unit;
        int repetitions;

        QJsonObject toJson() const;
        static HistoryRecord fromJson(const QJsonObject& json);
    };

    struct Exercise {
        QString name;
        QString muscleGroup;
        double currentValue;
        QString unit;
        int repetitions;
        QDateTime lastUpdated;
        QList<HistoryRecord> history;

        QJsonObject toJson() const;
        static Exercise fromJson(const QString& key, const QJsonObject& json);
    };

    enum Roles {
        NameRole = Qt::UserRole + 1,
        MuscleGroupRole,
        CurrentValueRole,
        UnitRole,
        RepetitionsRole,
        LastUpdatedRole,
        HistoryRole
    };

    explicit ExerciseModel(QObject *parent = nullptr);

    // QAbstractItemModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Métodos públicos
    Q_INVOKABLE void loadFromJson(const QJsonObject& json);
    Q_INVOKABLE QJsonObject toJson() const;
    Q_INVOKABLE void addExercise(const QString& name, const QString& muscleGroup,
                                 double value, const QString& unit, int reps);
    Q_INVOKABLE void updateExercise(int index, double value, int reps);
    Q_INVOKABLE void removeExercise(int index);

signals:
    void modelChanged();

private:
    QList<Exercise> m_exercises;
};

#endif // EXERCISEMODEL_H
