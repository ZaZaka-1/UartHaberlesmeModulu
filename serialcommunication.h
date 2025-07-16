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

public:
    Q_INVOKABLE void sendSpo2Settings(int frequency, int mode, int averaging);

    int waveformSample() const { return m_waveformSample; }
    explicit SerialCommunication(QObject *parent = nullptr);
    ~SerialCommunication();

    bool isConnected() const;

public slots:
    void reconnect();
    void stopDataStream();

signals:
    void waveformSampleReceived();
    void dataReceived(uint8_t code, const QByteArray &payload);
    void connectionStatusChanged(bool connected);
    void spo2PulseData(const QString &spo2, const QString &pulse);
    void ertData(uint8_t hr, uint8_t rr, float t1, float t2);
    void waveformDataReceived(uint8_t waveformValue);
    void modeChanged(int mode, const QString &modeStr);

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
    uint8_t currentMode = 0;
    int currentAveraging = 4; // seconds

    QList<uint8_t> spo2Buffer;
    QList<uint16_t> pulseBuffer;

    // Geçerli SpO2 ve nabız değerlerini saklayan değişkenler
    uint8_t lastValidSpo2 = 0;
    uint16_t lastValidPulse = 0;
    QString lastValidSpo2Str = "0";
    QString lastValidPulseStr = "0";
};

#endif // SERIALCOMMUNICATION_H
