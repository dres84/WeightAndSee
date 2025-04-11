#ifndef DATACENTER_H
#define DATACENTER_H

#include <QObject>
#include <QJsonObject>

class DataCenter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)

public:
    explicit DataCenter(QObject *parent = nullptr);

    QJsonObject data() const;

    // Métodos cambiados de public slots a Q_INVOKABLE
    Q_INVOKABLE void load();
    Q_INVOKABLE void save();
    Q_INVOKABLE void addExercise(const QString& name, const QString& muscleGroup,
                                 double value, const QString& unit, int reps);
    Q_INVOKABLE void updateExercise(const QString& name, double value, int reps);
    Q_INVOKABLE void removeExercise(const QString& name);
    Q_INVOKABLE void deleteFile();

signals:
    void dataChanged();

private:
    QString getFilePath() const;
    QJsonObject m_data;
    void ensureHistoriesExist();
    void loadDefaultData();
};

#endif // DATACENTER_H
