#include <QApplication>
#include <QWidget>
#include <QLabel>
#include <QGridLayout>
#include <QTimer>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QWidget pencere;
    pencere.setWindowTitle("Renkli Işıklar");

    QGridLayout *grid = new QGridLayout;

    QLabel *label1 = new QLabel("1");
    QLabel *label2 = new QLabel("2");
    QLabel *label3 = new QLabel("3");
    QLabel *label4 = new QLabel("4");

    QLabel* labels[4] = { label1, label2, label3, label4 };

    QString normalStyles[4] = {
        "background-color: darkred; color: white; font-size: 30px;",
        "background-color: darkgreen; color: white; font-size: 30px;",
        "background-color: darkblue; color: white; font-size: 30px;",
        "background-color: goldenrod; color: black; font-size: 30px;"
    };

    QString activeStyles[4] = {
        "background-color: red; color: white; font-size: 30px;",
        "background-color: lime; color: black; font-size: 30px;",
        "background-color: deepskyblue; color: black; font-size: 30px;",
        "background-color: yellow; color: black; font-size: 30px;"
    };

    for (int i = 0; i < 4; ++i) {
        labels[i]->setAlignment(Qt::AlignCenter);
        labels[i]->setStyleSheet(normalStyles[i]);
    }

    grid->addWidget(label1, 0, 0); // sol üst
    grid->addWidget(label2, 0, 1); // sağ üst
    grid->addWidget(label3, 1, 1); // sağ alt
    grid->addWidget(label4, 1, 0); // sol alt

    grid->setRowStretch(0, 1);
    grid->setRowStretch(1, 1);
    grid->setColumnStretch(0, 1);
    grid->setColumnStretch(1, 1);

    pencere.setLayout(grid);
    pencere.showFullScreen();  // Tam ekran

    int *current = new int(0);

    QTimer *timer = new QTimer;

    QObject::connect(timer, &QTimer::timeout, [=]() mutable {
        // Tüm label'ları normal hale getir
        for (int i = 0; i < 4; ++i) {
            labels[i]->setStyleSheet(normalStyles[i]);
        }

        // Aktif olan label'ı parlat
        labels[*current]->setStyleSheet(activeStyles[*current]);

        // Sonrakine geç (saat yönünde)
        *current = (*current + 1) % 4;
    });

    timer->start(1000); // 1 saniyede bir değişim

    return app.exec();
}

