#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QObject>
#include <QSerialPort>
#include <QByteArray>
#include <QTimer>
#include <QAbstractListModel>
#include <QVariantMap>

//SQL KOMUTLARI
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>

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
    void readData();
    void handleError(QSerialPort::SerialPortError error);
    void sendConnectionSequence();
    void startSequentialRequests();
    void sendNextPacket();
    void tryReconnect();  // Bu satırı ekleyin

private:
    bool errorLogged = false;

    void openSerialPort();
    QList<QByteArray> createIndividualCommands();
    QByteArray createSMMPacket(uint8_t code, const QByteArray &data);
    void parseBufferedData();
    void parsePacketByCode(uint8_t code, const QByteArray &payload);

    QDateTime lastInsertTime;

    QSerialPort *serial;
    QByteArray buffer;

    QString m_spo2;
    QString m_pulse;

    QTimer *connectionTimer;
    QTimer *dataRequestTimer;
    QTimer *sequentialTimer;

    QList<QByteArray> packetCommands;
    bool connectionSent;
    int currentPacketIndex;

    //SQL KISMI
    QSqlDatabase db;

    void initDatabase();
    void insertMeasurement(const QString &spo2, const QString &pulse);

private:
    // Mevcut değişkenlerinizin yanına ekleyin
    QDateTime lastSaveTime;
};

#endif // MAINWINDOW_H
