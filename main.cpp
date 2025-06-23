#include <QApplication>
#include <QWidget>
#include <QLabel>
#include <QGridLayout>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QWidget pencere;
    pencere.setWindowTitle("2 Label Yan Yana");

    QGridLayout *grid = new QGridLayout;

    QLabel *label1 = new QLabel(":D");
    label1->setStyleSheet("background-color: red; color: white; font-size: 48px;");
    label1->setAlignment(Qt::AlignCenter);

    QLabel *label2 = new QLabel(":D");
    label2->setStyleSheet("background-color: green; color: black; font-size: 48px;");
    label2->setAlignment(Qt::AlignCenter);

    grid->addWidget(label1, 0, 0);
    grid->addWidget(label2, 0, 1);

    grid->setRowStretch(0, 1);
    grid->setColumnStretch(0, 1);
    grid->setColumnStretch(1, 1);

    pencere.setLayout(grid);

    pencere.showFullScreen();

    return app.exec();
}

