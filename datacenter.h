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

public slots:
    void load();
    void save();
    void addExercise(const QString& name, const QString& muscleGroup,
                     double value, const QString& unit, int reps);
    void updateExercise(int index, double value, int reps);
    void removeExercise(int index);
    void deleteFile();

signals:
    void dataChanged();

private:
    QString getFilePath() const;
    QJsonObject m_data;
    void ensureHistoriesExist();
    void loadDefaultData();
};
#endif // DATACENTER_H

