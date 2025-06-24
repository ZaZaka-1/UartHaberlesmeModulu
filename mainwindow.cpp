#include "mainwindow.h"
#include <QVBoxLayout>
#include <QLineEdit>
#include <QPushButton>
#include <QTextEdit>

MainWindow::MainWindow(QWidget *parent)
    : QWidget(parent), serial(new QSerialPort(this))
{
    input = new QLineEdit(this);
    sendButton = new QPushButton("Gönder", this);
    output = new QTextEdit(this);
    output->setReadOnly(true);

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->addWidget(input);
    layout->addWidget(sendButton);
    layout->addWidget(output);
    setLayout(layout);
    resize(300, 200);
    setWindowTitle("Basit UART");

    // Seri port ayarları
    serial->setPortName("COM3"); // Linux ise ttyUSB0
    serial->setBaudRate(QSerialPort::Baud9600);
    serial->open(QIODevice::ReadWrite);

    connect(sendButton, &QPushButton::clicked, this, &MainWindow::sendData);
    connect(serial, &QSerialPort::readyRead, this, &MainWindow::readData);
}

void MainWindow::sendData()
{
    QByteArray data = input->text().toUtf8();
    serial->write(data);
}

void MainWindow::readData()
{
    QByteArray data = serial->readAll();
    output->append("Gelen: " + QString::fromUtf8(data));
}
