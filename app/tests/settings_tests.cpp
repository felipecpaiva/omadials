#include <QtTest>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlExpression>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QQuickItem>
#include <QTemporaryDir>
#include <QJsonDocument>
#include <QJsonObject>
#include "backend.h"
#include "theme.h"
class SettingsTests : public QObject {
    Q_OBJECT
private slots:
    void ipcUsesFixedArguments() {
        QTemporaryDir tools;
        QFile script(tools.filePath("omarchy-shell")); QVERIFY(script.open(QIODevice::WriteOnly));
        script.write("#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$HOME/argv\"\nprintf '%s\\n' '{\"version\":\"test\",\"controls\":[]}'\n");
        script.close(); QVERIFY(script.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner));
        QByteArray oldPath = qgetenv("PATH"); qputenv("PATH",tools.path().toUtf8());
        Backend backend; QSignalSpy received(&backend,&Backend::statusReceived);
        backend.refreshStatus(); QTRY_COMPARE(received.count(),1);
        QFile args(QDir::homePath()+"/argv"); QVERIFY(args.open(QIODevice::ReadOnly));
        QCOMPARE(args.readAll(),QByteArray("omadials\nstatus\n")); args.close();
        backend.showOnScreen(); QTRY_COMPARE(backend.status(),QString("Show on screen requested."));
        QVERIFY(args.open(QIODevice::ReadOnly)); QCOMPARE(args.readAll(),QByteArray("omadials\nopen\n"));
        qputenv("PATH",oldPath);
    }
    void writerAndWindow() {
        QTest::failOnWarning(QRegularExpression(".*qrc:.*"));
        Backend backend; Theme theme;
        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty("backend", &backend);
        engine.rootContext()->setContextProperty("desktopTheme", &theme);
        engine.load(QUrl("qrc:/qml/Main.qml"));
        QVERIFY(!engine.rootObjects().isEmpty());
        QObject *root = engine.rootObjects().first();
        auto *store = root->findChild<QObject*>("configStore"); QVERIFY(store);
        auto eval = [&](const QString &code) {
            QQmlExpression expression(engine.rootContext(),store,code);
            QVariant result = expression.evaluate();
            if (expression.hasError()) qWarning() << expression.error();
            return result;
        };
        QVERIFY(!QFile::exists(backend.path()));
        QVERIFY(eval("set('corner','top-right')").toBool());
        auto readText = [&] { return backend.read().value("text").toString(); };
        QString baseline = readText(); QVERIFY(baseline.contains("top-right"));
        QVERIFY(eval("canUndo").toBool()); eval("undo()");
        QVERIFY(readText().contains("bottom-left"));
        auto put = [&](const QByteArray &text) { QFile f(backend.path()); QVERIFY(f.open(QIODevice::WriteOnly)); QCOMPARE(f.write(text),text.size()); f.close(); eval("reload()"); };
        put("{\"version\":1,\"future\":{\"x\":42},\"controls\":{\"unknown\":{\"shown\":true}}}");
        QVERIFY(eval("set('corner','top-left')").toBool());
        auto obj = QJsonDocument::fromJson(readText().toUtf8()).object();
        QCOMPARE(obj.value("future").toObject().value("x").toInt(),42);
        QVERIFY(obj.value("controls").toObject().contains("unknown"));
        QString before = readText();
        QVERIFY(!eval("set('trigger.pushDelayMs',999)").toBool()); QCOMPARE(readText(),before);
        put("{"); QVERIFY(eval("readOnly").toBool());
        QVERIFY(!eval("set('corner','top-left')").toBool()); QCOMPARE(readText(),QString("{"));
        QVERIFY(eval("reset()").toBool()); eval("undo()"); QCOMPARE(readText(),QString("{"));
        put("{\"version\":99}"); QVERIFY(eval("readOnly").toBool());
        QVERIFY(!eval("reset()").toBool()); QCOMPARE(readText(),QString("{\"version\":99}"));
        put("{\"version\":1}");
        QVERIFY(!backend.write("{}","different",true));
        QVERIFY(eval("set('corner','bottom-right')").toBool());
        QFile external(backend.path()); QVERIFY(external.open(QIODevice::WriteOnly));
        external.write("{\"version\":1,\"size\":\"L\"}"); external.close();
        QTRY_COMPARE(eval("value('size')").toString(),QString("L"));
        QVERIFY(!eval("canUndo").toBool());
        auto pages = root->findChild<QObject*>("pages"); QVERIFY(pages);
        auto window = qobject_cast<QQuickWindow*>(root); QVERIFY(window);
        QVERIFY(QTest::qWaitForWindowExposed(window)); QTest::qWait(100);
        std::function<QQuickItem*(QQuickItem*)> findTab = [&](QQuickItem *item) -> QQuickItem* {
            if (item->property("text").toString() == "Controls" && item->inherits("QQuickAbstractButton")) return item;
            for (auto *child : item->childItems()) if (auto *found = findTab(child)) return found;
            return nullptr;
        };
        auto *tab = findTab(window->contentItem()); QVERIFY(tab);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,tab->mapToScene(QPointF(tab->width()/2,tab->height()/2)).toPoint());
        QTest::qWait(100); QCOMPARE(pages->property("currentIndex").toInt(),1);
        for (int i=0;i<4;++i) {
            pages->setProperty("currentIndex",i); QTest::qWait(100);
            if (i == 1) {
                std::function<void(QQuickItem*)> expand = [&](QQuickItem *item) {
                    if (item->property("controlKey").isValid()) item->setProperty("expanded",true);
                    for (auto *child : item->childItems()) expand(child);
                };
                auto *pageItem = qobject_cast<QQuickItem*>(pages->property("item").value<QObject*>());
                QVERIFY(pageItem); expand(pageItem); QTest::qWait(100);
            }
            // A picture of each page, for design review (tests/page-0.png ... page-3.png).
            if (qEnvironmentVariableIsSet("OMADIALS_PAGE_SHOTS")) window->grabWindow().save(QString("page-%1.png").arg(i));
        }
        pages->setProperty("currentIndex",0); QTest::qWait(100);
        QVERIFY(window->grabWindow().save("preview.png"));
        auto scroll = root->findChild<QObject*>("scroll"); QVERIFY(scroll);
        QObject *flick = scroll->property("contentItem").value<QObject*>(); QVERIFY(flick);
        flick->setProperty("contentY",flick->property("contentHeight").toReal()-flick->property("height").toReal());
        QTest::qWait(100);
        QVERIFY(window->grabWindow().save("preview-layout.png"));
        // Check live replacement of the accent file, independent of the desktop.
        QTemporaryDir themeDir; QDir(themeDir.path()).mkpath("theme");
        Theme isolated(themeDir.path()); QCOMPARE(isolated.accent(),QString("#FFD60A"));
        QFile colors(themeDir.filePath("theme/colors.toml")); QVERIFY(colors.open(QIODevice::WriteOnly));
        colors.write("accent = \"#123456\"\n"); colors.close();
        QTRY_COMPARE(isolated.accent(),QString("#123456"));
    }
};
int main(int argc,char **argv) {
    QTemporaryDir home;
    qputenv("HOME",home.path().toUtf8()); qputenv("QT_QPA_PLATFORM","offscreen");
    qputenv("QT_QPA_PLATFORMTHEME",""); qputenv("QT_QUICK_BACKEND","software");
    qputenv("HYPRLAND_INSTANCE_SIGNATURE",""); qputenv("QT_FORCE_STDERR_LOGGING","1");
    QGuiApplication app(argc,argv); QQuickStyle::setStyle("Material");
    SettingsTests tests; return QTest::qExec(&tests,argc,argv);
}
#include "settings_tests.moc"
