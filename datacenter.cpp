#include "datacenter.h"
#include <QStandardPaths>
#include <QDebug>

DataCenter::DataCenter(QObject *parent) : QObject(parent) {
}

QJsonObject DataCenter::data() const {
    return m_data;
}

void DataCenter::save() {
    QFile file(getFilePath());
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("No se pudo abrir el archivo para escritura");
        return;
    }
    QJsonDocument doc(m_data);
    file.write(doc.toJson());
    file.close();
}

QJsonObject DataCenter::load() {
    QFile file(getFilePath());
    if (file.exists() && file.open(QIODevice::ReadOnly)) {
        qDebug() << "File exists in " << getFilePath();
        QByteArray data = file.readAll();
        file.close();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isNull() && doc.isObject()) {
            m_data = doc.object();
            emit dataChanged();
            return m_data;
        }
    }
    qDebug() << "File doesn't exist in " << getFilePath();
    loadDefaultData();
    save();
    emit dataChanged();
    return m_data;
}

void DataCenter::loadDefaultData() {
    m_data = {
        {"exercises", QJsonObject {
                        {"Sentadillas con peso", QJsonObject{{"part", "tren_inferior"}, {"selectedWeight", 12}, {"history", QJsonArray()}}},
                        {"abdominales", QJsonObject{{"part", "core"}, {"selectedWeight", 0}, {"history", QJsonArray()}}},
                        {"press_banca", QJsonObject{{"part", "tren_superior"}, {"selectedWeight", 20}, {"history", QJsonArray()}}}
                      }}
    };
}

QString DataCenter::getFilePath() const {
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/data.json";
}

void DataCenter::deleteFile() {
    QFile file(getFilePath());
    if (file.exists()) {
        if (file.remove()) {
            qDebug("Archivo eliminado correctamente");
        } else {
            qWarning("No se pudo eliminar el archivo");
        }
    } else {
        qWarning("El archivo no existe");
    }
}
