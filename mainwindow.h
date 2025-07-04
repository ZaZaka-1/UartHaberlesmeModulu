#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QObject>
#include <QByteArray>
#include <QAbstractListModel>
#include <QVariantMap>

//SQL KOMUTLARI
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>

// Forward declaration
class SerialCommunication;

class MainWindow : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString spo2 READ spo2 NOTIFY spo2Changed)
    Q_PROPERTY(QString pulse READ pulse NOTIFY pulseChanged)
    Q_PROPERTY(bool serialConnected READ isSerialConnected NOTIFY serialConnectedChanged)

    //main2.qml için
public:
    Q_INVOKABLE QVariantList getMeasurements(); // Tüm ölçümleri al
    Q_INVOKABLE QVariantList getRecentMeasurements(int limit = 50); // Son N ölçümü al
    Q_INVOKABLE void clearMeasurements(); // Tüm ölçümleri temizle
    Q_INVOKABLE int getMeasurementCount();

public slots:
    void stopDataStream();

signals:
    void measurementAdded();

public:
    explicit MainWindow(QObject *parent = nullptr);
    ~MainWindow();

    QString spo2() const { return m_spo2; }
    QString pulse() const { return m_pulse; }
    bool isSerialConnected() const;

    Q_INVOKABLE QVariantList getMeasurementsFromDatabase(int limit);
    Q_INVOKABLE int getTotalMeasurementCount();
    Q_INVOKABLE void clearDatabase();

signals:
    void spo2Changed();
    void pulseChanged();
    void serialConnectedChanged();

public slots:
    void reconnectSerial();  // QML'den çağırılabilir

private slots:
    void handleSpo2PulseData(const QString &spo2, const QString &pulse);
    void handleErtData(uint8_t hr, uint8_t rr, float t1, float t2);

private:
    SerialCommunication *serialComm;

    QString m_spo2;
    QString m_pulse;

    QDateTime lastInsertTime;
    QDateTime lastSaveTime;

    //SQL KISMI
    QSqlDatabase db;

    void initDatabase();
    void insertMeasurement(const QString &spo2, const QString &pulse);
};

#endif // MAINWINDOW_H
