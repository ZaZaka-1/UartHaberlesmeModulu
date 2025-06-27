#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("StajProje_1");
    app.setOrganizationName("YourOrganization"); // İsteğe bağlı

    MainWindow backend;

    QQmlApplicationEngine engine;

    // Backend nesnesini QML'e "backend" adıyla bağla
    engine.rootContext()->setContextProperty("backend", &backend);

    // QML dosyasını yükle
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection
        );

    engine.load(url);

    return app.exec();
}
