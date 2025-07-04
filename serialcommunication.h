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
    explicit SerialCommunication(QObject *parent = nullptr);
    ~SerialCommunication();

    bool isConnected() const;

public slots:
    void reconnect();
    void stopDataStream();

signals:
    void dataReceived(uint8_t code, const QByteArray &payload);
    void connectionStatusChanged(bool connected);
    void spo2PulseData(const QString &spo2, const QString &pulse);
    void ertData(uint8_t hr, uint8_t rr, float t1, float t2);

private slots:
    void readData();
    void handleError(QSerialPort::SerialPortError error);
    void sendConnectionSequence();
    void startSequentialRequests();
    void sendNextPacket();

private:
    void openSerialPort();
    QList<QByteArray> createIndividualCommands();
    QByteArray createSMMPacket(uint8_t code, const QByteArray &data);
    void parseBufferedData();
    void parsePacketByCode(uint8_t code, const QByteArray &payload);

    QSerialPort *serial;
    QByteArray buffer;

    QTimer *connectionTimer;
    QTimer *dataRequestTimer;
    QTimer *sequentialTimer;

    QList<QByteArray> packetCommands;
    bool connectionSent;
    int currentPacketIndex;
    bool errorLogged;
};

#endif // SERIALCOMMUNICATION_H
