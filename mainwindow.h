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
    Q_PROPERTY(int currentFrequency READ currentFrequency NOTIFY frequencyChanged) // Yeni eklenen property
    Q_PROPERTY(QVariantList waveformData READ waveformData NOTIFY waveformDataChanged)

public:
    void someFunction();
    explicit MainWindow(QObject *parent = nullptr);
    ~MainWindow();

    QString spo2() const { return m_spo2; }
    QString pulse() const { return m_pulse; }
    bool isSerialConnected() const;
    int currentFrequency() const { return m_currentFrequency; } // Yeni eklenen getter

    //main2.qml için
    QVariantList waveformData() const { return m_waveformData; }

    Q_INVOKABLE QVariantList getMeasurements(); // Tüm ölçümleri al
    Q_INVOKABLE QVariantList getRecentMeasurements(int limit = 50); // Son N ölçümü al
    Q_INVOKABLE void clearMeasurements(); // Tüm ölçümleri temizle
    Q_INVOKABLE int getMeasurementCount();
    Q_INVOKABLE QVariantList getMeasurementsFromDatabase(int limit);
    Q_INVOKABLE int getTotalMeasurementCount();
    Q_INVOKABLE void clearDatabase();
    Q_INVOKABLE void sendSpo2SettingsFromQml(int frequency, int mode, int averaging);

signals:
    void spo2Changed();
    void pulseChanged();
    void serialConnectedChanged();
    void measurementAdded();
    void waveformDataChanged();
    void realTimeWaveformPoint(int amplitude);
    void frequencyChanged(int newFrequency); // Yeni eklenen sinyal

public slots:
    void stopDataStream();
    void onWaveformSampleReceived();
    void reconnectSerial();  // QML'den çağırılabilir

private slots:
    void sendSpo2Settings(int frequency, int mode, int averaging);
    void handleWaveformData(uint8_t waveformValue);
    void handleSpo2PulseData(const QString &spo2, const QString &pulse);
    void handleErtData(uint8_t hr, uint8_t rr, float t1, float t2);
    void handleFrequencyChanged(int frequency); // Yeni eklenen slot

private:
    QVariantList m_waveformData;
    static const int MAX_WAVEFORM_POINTS = 200;

    SerialCommunication *serialComm;

    int m_waveformSample = 0;
    int m_currentFrequency = 50; // Yeni eklenen değişken (default 50Hz)

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
