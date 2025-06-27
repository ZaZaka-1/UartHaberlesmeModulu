#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QObject>
#include <QSerialPort>
#include <QTimer>
#include <QByteArray>
#include <QString>  // Eksikti, QString için gerekli

class MainWindow : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString spo2Value READ spo2Value NOTIFY spo2Changed)
    Q_PROPERTY(QString pulseValue READ pulseValue NOTIFY pulseChanged)

public:
    explicit MainWindow(QObject *parent = nullptr);
    ~MainWindow();  // Eksikti: Bellek sızıntısını önlemek için gerekli

    QString spo2Value() const { return m_spo2; }
    QString pulseValue() const { return m_pulse; }

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
    void parseBufferedData();
    void parsePacketByCode(uint8_t code, const QByteArray &payload);
    QList<QByteArray> createIndividualCommands();
    QByteArray createSMMPacket(uint8_t code, const QByteArray &data);

    QSerialPort *serial = nullptr;
    QTimer *connectionTimer = nullptr;
    QTimer *dataRequestTimer = nullptr;
    QTimer *sequentialTimer = nullptr;

    QByteArray buffer;
    bool connectionSent = false;
    QList<QByteArray> packetCommands;
    int currentPacketIndex = 0;

    QString m_spo2;
    QString m_pulse;

    Q_DISABLE_COPY(MainWindow)  // Kopyalamayı engelle
};

#endif // MAINWINDOW_H
