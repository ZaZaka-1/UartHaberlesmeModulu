#ifndef SERIALCOMMUNICATION_H
#define SERIALCOMMUNICATION_H

#include <QObject>
#include <QSerialPort>
#include <QByteArray>
#include <QTimer>
#include <QDebug>

class SerialCommunication : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int waveformSample READ waveformSample NOTIFY waveformSampleChanged)
    Q_PROPERTY(int currentFrequency READ currentFrequency NOTIFY frequencyChanged)
    Q_PROPERTY(int currentMode READ currentMode NOTIFY modeChanged)
    Q_PROPERTY(int currentAveraging READ currentAveraging NOTIFY averagingChanged)

public:
    explicit SerialCommunication(QObject *parent = nullptr);
    ~SerialCommunication();

    // Q_INVOKABLE fonksiyonlar
    Q_INVOKABLE void sendSpo2Settings(int frequency, int mode, int averaging);
    Q_INVOKABLE bool isConnected() const;
    Q_INVOKABLE void reconnect();
    Q_INVOKABLE void stopDataStream();

    // Getter fonksiyonlar
    int waveformSample() const { return m_waveformSample; }
    int currentFrequency() const { return m_currentFrequency; }
    int currentMode() const { return m_currentMode; }
    int currentAveraging() const { return m_currentAveraging; }

    // Waveform verilerini QML için erişilebilir hale getir
    Q_INVOKABLE QList<int> getWaveformBuffer() const { return m_waveformBuffer; }
    Q_INVOKABLE int getWaveformBufferSize() const { return m_waveformBuffer.size(); }

signals:
    void waveformSampleChanged();
    void frequencyChanged(int frequency);
    void modeChanged(int mode);
    void averagingChanged(int averaging);
    void dataReceived(uint8_t code, const QByteArray &payload);
    void connectionStatusChanged(bool connected);
    void spo2PulseData(const QString &spo2, const QString &pulse);
    void ertData(uint8_t hr, uint8_t rr, float t1, float t2);
    void waveformDataReceived(uint8_t waveformValue);
    void waveformBufferUpdated();

    void frequencyReceived(int frequency);
    void waveformSampleReceived();

private:

    // Fonksiyonlar
    void readData();
    void handleError(QSerialPort::SerialPortError error);
    void sendConnectionSequence();
    void startSequentialRequests();
    void sendNextPacket();
    uint8_t calculateSpo2SettingByte(int frequency, int mode, int averaging);
    void openSerialPort();
    QList<QByteArray> createIndividualCommands();
    QByteArray createSMMPacket(uint8_t code, const QByteArray &data);
    void parseBufferedData();
    void parsePacketByCode(uint8_t code, const QByteArray &payload);
    void processAveraging();
    bool isValidSpo2(uint8_t spo2, uint8_t mode);
    bool isValidPulse(uint16_t pulse, uint8_t mode);
    void addToBuffer(uint8_t spo2, uint16_t pulse);
    void updateWaveformBuffer(uint8_t waveformValue);

    // Değişkenler
    QSerialPort *serial;
    QByteArray buffer;
    uint8_t m_waveformSample = 0;
    QTimer *connectionTimer;
    QTimer *dataRequestTimer;
    QTimer *sequentialTimer;
    QTimer *averagingTimer;

    QList<QByteArray> packetCommands;
    bool connectionSent;
    int currentPacketIndex;
    bool errorLogged;

    // Ayar değişkenleri
    int m_currentMode = 0;
    int m_currentAveraging = 4;
    int m_currentFrequency = 50;

    // Buffer'lar
    QList<uint8_t> spo2Buffer;
    QList<uint16_t> pulseBuffer;
    QList<int> m_waveformBuffer;  // PDF export için waveform verilerini sakla
    static const int MAX_WAVEFORM_BUFFER_SIZE = 1000;  // Maximum buffer size

    // Geçerli SpO2 ve nabız değerlerini saklayan değişkenler
    uint8_t lastValidSpo2 = 0;
    uint16_t lastValidPulse = 0;
    QString lastValidSpo2Str = "0";
    QString lastValidPulseStr = "0";
};

#endif // SERIALCOMMUNICATION_H
