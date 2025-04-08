#ifndef DATACENTER_H
#define DATACENTER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include <QFile>
#include <QDate>
#include <QQmlEngine>

class DataCenter : public QObject {
    Q_OBJECT
    Q_PROPERTY(QJsonObject data READ data NOTIFY dataChanged)

public:
    explicit DataCenter(QObject *parent = nullptr);
    QJsonObject data() const;
    Q_INVOKABLE QJsonObject load();
    Q_INVOKABLE void save();
    Q_INVOKABLE void deleteFile();
    Q_INVOKABLE void addExercise(const QString &name, const QString &part, const QString &unit);
    Q_INVOKABLE void deleteExercise(const QString &name);
    Q_INVOKABLE void updateExerciseWeight(const QString &exerciseName, int newWeight, QString unit);
    Q_INVOKABLE void saveSectionStates(const QJsonObject &sections);
    Q_INVOKABLE QJsonObject loadSectionStates();
    Q_INVOKABLE void updateModel();
signals:
    void dataChanged();
    void sectionStatesChanged();

private:
    void loadDefaultData();
    QString getFilePath() const;
    QJsonObject m_data;
};

#endif // DATACENTER_H
