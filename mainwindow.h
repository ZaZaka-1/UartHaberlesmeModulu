#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QWidget>
#include <QSerialPort>

class QLineEdit;
class QPushButton;
class QTextEdit;

class MainWindow : public QWidget
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);

private slots:
    void connectSerial();
    void sendData();
    void readData();

private:
    QSerialPort *serial;
    QLineEdit *input;
    QPushButton *sendButton;
    QTextEdit *output;
};

#endif // MAINWINDOW_H
