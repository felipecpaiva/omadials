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
            if (item->property("text").toString() == "Rings" && item->inherits("QQuickAbstractButton")) return item;
            for (auto *child : item->childItems()) if (auto *found = findTab(child)) return found;
            return nullptr;
        };
        auto *tab = findTab(window->contentItem()); QVERIFY(tab);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,tab->mapToScene(QPointF(tab->width()/2,tab->height()/2)).toPoint());
        QTest::qWait(100); QCOMPARE(pages->property("currentIndex").toInt(),1);
        const bool shots = qEnvironmentVariableIsSet("OMADIALS_PAGE_SHOTS");
        auto shot = [&](int n) { if (shots) QVERIFY(window->grabWindow().save(QString("page-%1.png").arg(n))); };
        for (int i=0;i<5;++i) {
            pages->setProperty("currentIndex",i); QTest::qWait(100);
            QVERIFY(root->findChild<QObject*>("livePreview"));
            shot(i);
        }
        std::function<QQuickItem*(QQuickItem*,std::function<bool(QQuickItem*)>)> findItem = [&](QQuickItem *item, std::function<bool(QQuickItem*)> match) -> QQuickItem* {
            if (match(item)) return item;
            for (auto *child : item->childItems()) if (auto *found = findItem(child,match)) return found;
            return nullptr;
        };
        auto button = [&](const QString &text) { return findItem(window->contentItem(),[&](QQuickItem *i) { return i->property("text").toString()==text && i->inherits("QQuickAbstractButton") && i->isVisible(); }); };
        auto click = [&](QQuickItem *item) { QVERIFY(item); QVERIFY(item->isEnabled()); QMetaObject::invokeMethod(item,"clicked"); QTest::qWait(100); };
        auto flick = root->findChild<QObject*>("scroll")->property("contentItem").value<QObject*>(); QVERIFY(flick);
        // Rings edit list: Remove only hides a ring, Add shows it again, the corner fills up at its capacity.
        eval("set('size','M')"); pages->setProperty("currentIndex",1); QTest::qWait(100);
        QVERIFY(eval("set('controls.mic.icon','volume')").toBool());
        click(button("Remove Microphone from the corner"));
        QCOMPARE(eval("value('controls.mic.shown')").toBool(),false);
        QCOMPARE(eval("value('controls.mic.icon')").toString(),QString("volume"));
        QVERIFY(eval("config.dials.some(function(d) { return d.id==='mic' && d.style.knob==='round' })").toBool());
        click(button("Add Microphone to the corner")); QVERIFY(eval("set('controls.mic.icon','default')").toBool());
        QCOMPARE(eval("value('controls.mic.shown')").toBool(),true);
        QCOMPARE(eval("config.dials.length").toInt(),3);
        auto *full = root->findChild<QObject*>("fullLine"); QVERIFY(full); QVERIFY(full->property("visible").toBool());
        auto *addCharge = button("Add Charge limit to the corner"); QVERIFY(addCharge); QVERIFY(!addCharge->isEnabled());
        QVERIFY(eval("set('size','L')").toBool()); QTest::qWait(100);
        QVERIFY(!full->property("visible").toBool());
        click(button("Add Charge limit to the corner"));
        QVERIFY(eval("value('controls.chargeLimit.shown')").toBool());
        QCOMPARE(eval("config.dials.find(function(d) { return d.id==='chargeLimit' }).order").toInt(),3);
        click(button("Remove Charge limit from the corner"));
        QVERIFY(eval("config.dials.some(function(d) { return d.id==='chargeLimit' })").toBool());
        click(button("Add a new display ring for Laptop battery"));
        QCOMPARE(eval("config.readoutRings.length").toInt(),1);
        QVERIFY(eval("config.controls[config.readoutRings[0].id].shown && config.readoutRings[0].source==='laptopBattery'").toBool());
        click(button("Remove Laptop battery from the corner"));
        QCOMPARE(eval("config.readoutRings.length").toInt(),1);
        // Up and down buttons appear while the row has keyboard focus.
        window->requestActivate(); QVERIFY(!button(QString::fromUtf8("↑")));
        auto *handle = findItem(window->contentItem(),[](QQuickItem *i) { return i->objectName()=="moveHandle"; }); QVERIFY(handle);
        handle->forceActiveFocus(Qt::TabFocusReason); QTest::qWait(50); QVERIFY(button(QString::fromUtf8("↑")));
        handle->setFocus(false); window->contentItem()->forceActiveFocus(); QTest::qWait(50);
        // Moving keeps the order values unique and puts the ring where its neighbour was.
        auto *pageItem = qobject_cast<QQuickItem*>(pages->property("item").value<QObject*>()); QVERIFY(pageItem);
        QMetaObject::invokeMethod(pageItem,"move",Q_ARG(QVariant,"mic"),Q_ARG(QVariant,-1)); QTest::qWait(100);
        QCOMPARE(eval("config.dials.find(function(d) { return d.id==='mic' }).order").toInt(),1);
        QCOMPARE(eval("config.dials.find(function(d) { return d.id==='volume' }).order").toInt(),2);
        QVERIFY(button(QString::fromUtf8("↑")));
        // Dragging Microphone's handle onto Brightness puts it first.
        QList<QQuickItem*> handles;
        std::function<void(QQuickItem*)> collect = [&](QQuickItem *i) { if (i->objectName()=="moveHandle" && i->isVisible()) handles << i; for (auto *c : i->childItems()) collect(c); };
        collect(window->contentItem()); QCOMPARE(handles.size(),3);
        std::sort(handles.begin(),handles.end(),[](QQuickItem *a,QQuickItem *b) { return a->mapToScene(QPointF()).y() < b->mapToScene(QPointF()).y(); });
        QPoint from = handles[1]->mapToScene(QPointF(handles[1]->width()/2,handles[1]->height()/2)).toPoint();
        QPoint to = handles[0]->mapToScene(QPointF(handles[0]->width()/2,handles[0]->height()/2)).toPoint();
        QTest::mousePress(window,Qt::LeftButton,Qt::NoModifier,from);
        for (int s=1;s<=10;++s) QTest::mouseMove(window,from+(to-from)*s/10,10);
        QTest::mouseRelease(window,Qt::LeftButton,Qt::NoModifier,to); QTest::qWait(100);
        QCOMPARE(eval("config.dials.find(function(d) { return d.id==='mic' }).order").toInt(),0);
        QCOMPARE(eval("config.dials.find(function(d) { return d.id==='brightness' }).order").toInt(),1);
        if (shots) { flick->setProperty("contentY",flick->property("contentHeight").toReal()-flick->property("height").toReal()); QTest::qWait(100); shot(5); }
        // Edit opens the sheet for that one ring; the common style switch reveals the ring's own choices.
        flick->setProperty("contentY",0);
        click(button("Edit Brightness"));
        QCOMPARE(root->property("editingId").toString(),QString("brightness"));
        auto *sheetLoader = root->findChild<QObject*>("sheetLoader"); QVERIFY(sheetLoader); QVERIFY(sheetLoader->property("active").toBool());
        auto *styleSwitch = root->findChild<QObject*>("commonStyleSwitch"); QVERIFY(styleSwitch);
        QVERIFY(styleSwitch->property("checked").toBool());
        QMetaObject::invokeMethod(styleSwitch,"toggle"); QMetaObject::invokeMethod(styleSwitch,"toggled"); QTest::qWait(100);
        QVERIFY(!styleSwitch->property("checked").toBool());
        if (shots) {
            auto *sheetFlick = root->findChild<QObject*>("sheetScroll")->property("contentItem").value<QObject*>(); QVERIFY(sheetFlick);
            sheetFlick->setProperty("contentY",260); QTest::qWait(100); shot(6); sheetFlick->setProperty("contentY",0);
        }
        // Clicking a toggle in the preview opens the Toggles page with its sheet.
        auto *preview = qobject_cast<QQuickItem*>(root->findChild<QObject*>("livePreview")); QVERIFY(preview);
        QQmlExpression toggleAt(engine.rootContext(),preview,"(function() { let R=capacity.R, r=capacity.toggleRadius, a=shapes.angles[0]*Math.PI/180; return [r*Math.sin(a)*0.6,(R-r*Math.cos(a))*0.6, shapes.toggles[0].id] })()");
        QVariantList at = toggleAt.evaluate().toList(); QCOMPARE(at.size(),3);
        auto *canvas = findItem(preview,[](QQuickItem *i) { return i->inherits("QQuickCanvasItem"); }); QVERIFY(canvas);
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,canvas->mapToScene(QPointF(at[0].toReal(),at[1].toReal())).toPoint()); QTest::qWait(150);
        QCOMPARE(pages->property("currentIndex").toInt(),2);
        QCOMPARE(root->property("editingId").toString(),at[2].toString());
        QVERIFY(button("Edit Wi-Fi")); shot(7);
        // Narrow window: the preview moves on top and the sheet becomes a bottom sheet.
        // A rejected edit is reported in the sheet when the list is hidden behind it.
        window->resize(900,850); QTest::qWait(150);
        QVERIFY(!eval("set('controls.wifi.icon','bad name!')").toBool()); QTest::qWait(100);
        QVERIFY(findItem(window->contentItem(),[](QQuickItem *i) { return i->isVisible() && i->property("text").toString().startsWith("Control appearance:"); }));
        shot(8); window->resize(1200,850); QTest::qWait(100);
        click(button("Done")); QVERIFY(!sheetLoader->property("active").toBool());
        pages->setProperty("currentIndex",0); QTest::qWait(100);
        QVERIFY(window->grabWindow().save("preview.png"));
        auto scroll = root->findChild<QObject*>("scroll"); QVERIFY(scroll);

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
