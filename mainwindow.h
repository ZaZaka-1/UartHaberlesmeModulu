#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QSerialPort>
#include <QTimer>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void readSerialData();
    void handleError(QSerialPort::SerialPortError error);
    void sendKeepAlive();

private:
    QSerialPort *serial;
    QTimer keepAliveTimer;
    bool protocolSwitched;
    QByteArray buffer;

    void openSerialPort();
    void closeSerialPort();
    void processBuffer();
    quint8 calculateChecksum(const QByteArray &data);
};

#endif // MAINWINDOW_H
