#include <QApplication>
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    w.show(); // Pencereyi göster
    qDebug() << "Program başlatıldı.";
    return a.exec();
}
