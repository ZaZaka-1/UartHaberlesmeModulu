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

    // ✅ Yeni sinyal: Waveform verisi için
    void waveformDataReceived(uint8_t waveformValue);

private slots:
    void readData();
    void handleError(QSerialPort::SerialPortError error);
    void sendConnectionSequence();
    void startSequentialRequests();
    void sendNextPacket();

private:
    uint8_t calculateSpo2SettingByte(int frequency, int mode, int averaging);

    void openSerialPort();
    QList<QByteArray> createIndividualCommands();
    QByteArray createSMMPacket(uint8_t code, const QByteArray &data);
    void parseBufferedData();
    void parsePacketByCode(uint8_t code, const QByteArray &payload);

    QSerialPort *serial;
    QByteArray buffer;
    uint8_t m_waveformSample = 0;
    QTimer *connectionTimer;
    QTimer *dataRequestTimer;
    QTimer *sequentialTimer;

    QList<QByteArray> packetCommands;
    bool connectionSent;
    int currentPacketIndex;
    bool errorLogged;
};

#endif // SERIALCOMMUNICATION_H
