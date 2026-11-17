#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQuickStyle>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFile>
#include <QSaveFile>
#include <QDir>
#include <cstdio>
#include <memory>
#include "backend.h"
#include "theme.h"
#include "translator.h"
int main(int argc, char **argv) {
    const bool cli = argc > 1 && QByteArray(argv[1]) != "open";
    if (cli) { qputenv("QT_QPA_PLATFORM","offscreen"); qputenv("QT_QPA_PLATFORMTHEME",""); }
    QGuiApplication app(argc,argv);
    app.setApplicationName("omadials-settings"); app.setApplicationVersion("0.7.0");
    app.setDesktopFileName("omadials-settings"); QQuickStyle::setStyle("Material");
    Translator translator; app.installTranslator(&translator);
    Theme theme; Backend backend; QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("desktopTheme",&theme);
    engine.rootContext()->setContextProperty("backend",&backend);
    QObject::connect(&translator,&Translator::changed,&engine,&QQmlEngine::retranslate);
    if (cli) {
        const QStringList args = app.arguments().mid(1);
        QString error;
        bool ok = false;
        QJsonObject result;
        if (args == QStringList{"check","--json"}) {
            QQmlComponent component(&engine,QUrl("qrc:/qml/ConfigStore.qml"));
            std::unique_ptr<QObject> store(component.createWithInitialProperties({{"io",QVariant::fromValue(&backend)}}));
            if (!store) error = component.errorString();
            else {
                QJSValue object = engine.newQObject(store.get());
                QJsonArray errors = QJsonValue::fromVariant(object.property("errors").toVariant()).toArray();
                ok = store->property("loaded").toBool() && !store->property("readOnly").toBool() && errors.isEmpty();
                result = {{"ok",ok},{"readOnly",store->property("readOnly").toBool()},{"errors",errors}};
                if (!ok) error = "Config has problems. See JSON errors.";
            }
        } else if (args == QStringList{"skill","install","--json"}) {
            const QString directory = QDir::homePath()+"/.agents/skills/omadials-settings";
            QFile bundled(":/agent-SKILL.md"); QSaveFile file(directory+"/SKILL.md");
            ok = bundled.open(QIODevice::ReadOnly) && QDir().mkpath(directory) && file.open(QIODevice::WriteOnly);
            if (ok) { const auto bytes = bundled.readAll(); ok = file.write(bytes) == bytes.size() && file.commit(); }
            if (!ok) error = "Cannot install the bundled agent skill.";
        } else error = "Usage: omadials-settings [open | check --json | skill install --json]";
        result.insert("ok",ok);
        if (!error.isEmpty()) { result.insert("error",error); fprintf(stderr,"%s\n",qPrintable(error)); }
        const auto bytes = QJsonDocument(result).toJson(QJsonDocument::Compact);
        printf("%s\n",bytes.constData());
        return ok ? 0 : 1;
    }
    engine.load(QUrl("qrc:/qml/Main.qml"));
    if (engine.rootObjects().isEmpty()) return 1;
    return app.exec();
}
