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
    void openSerialPort();
    void closeSerialPort();
    quint8 calculateChecksum(const QByteArray &data);

    QSerialPort *serial;
    QByteArray buffer;          // Gelen veriyi depolamak için buffer
    QTimer keepAliveTimer;
    bool protocolSwitched;
};

#endif // MAINWINDOW_H
