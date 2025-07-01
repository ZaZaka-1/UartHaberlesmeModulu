#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QObject>
#include <QSerialPort>
#include <QByteArray>
#include <QTimer>

class MainWindow : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString spo2 READ spo2 NOTIFY spo2Changed)
    Q_PROPERTY(QString pulse READ pulse NOTIFY pulseChanged)

public:
    explicit MainWindow(QObject *parent = nullptr);
    ~MainWindow();

    QString spo2() const { return m_spo2; }
    QString pulse() const { return m_pulse; }

signals:
    void spo2Changed();
    void pulseChanged();

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

    QString m_spo2;
    QString m_pulse;

    QTimer *connectionTimer;
    QTimer *dataRequestTimer;
    QTimer *sequentialTimer;

    QList<QByteArray> packetCommands;
    bool connectionSent;
    int currentPacketIndex;
};

#endif // MAINWINDOW_H
