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
                                 double value, const QString& unit, int sets, int reps);
    Q_INVOKABLE void updateExercise(const QString& name, double value, const QString& unit, int sets, int reps);
    Q_INVOKABLE void removeExercise(const QString& name);
    Q_INVOKABLE void removeHistoryEntry(const QString& exerciseName, int index);
    Q_INVOKABLE void reloadSampleData();
    Q_INVOKABLE void deleteAllExercises();

    Q_INVOKABLE QString getMuscleGroup(const QString& exerciseName) const;
    Q_INVOKABLE double getCurrentValue(const QString& exerciseName) const;
    Q_INVOKABLE QString getUnit(const QString& exerciseName) const;
    Q_INVOKABLE int getRepetitions(const QString& exerciseName) const;
    Q_INVOKABLE int getSets(const QString& exerciseName) const;

    // Para las gráficas
    Q_INVOKABLE QVariantList getExerciseHistoryDetailed(const QString& exerciseName) const;

    // Para importar y exportar datos
    Q_INVOKABLE void exportData(const QString& filePath);
    Q_INVOKABLE void importData(const QUrl &fileUrl);

signals:
    void dataChanged();
    void showMessage(QString title, QString message, QString messageType = "info");

private:
    QString getFilePath() const;
    QJsonObject m_data;
    void loadData();
    void loadEmptyData();
    void loadTestData();
    void loadSampleData();
};

#endif // DATACENTER_H
