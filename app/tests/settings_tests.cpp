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
#include <QAccessible>
#include "backend.h"
#include "theme.h"
class SettingsTests : public QObject {
    Q_OBJECT
private slots:
    void sweep() {
        // Settings sweep (2026-11-17): every page tall and narrow, in the theme named by OMADIALS_SWEEP_THEME, plus a dump
        // of every named control. Runs only when OMADIALS_SWEEP is set; writes sweep-*.png and sweep-controls.txt.
        if (!qEnvironmentVariableIsSet("OMADIALS_SWEEP")) QSKIP("set OMADIALS_SWEEP to run");
        const QString themeName = qEnvironmentVariable("OMADIALS_SWEEP_THEME","tokyo-night");
        QTemporaryDir state; QDir().mkpath(state.filePath("theme"));
        QVERIFY(QFile::copy("/usr/share/omarchy/themes/"+themeName+"/colors.toml",state.filePath("theme/colors.toml")));
        QFile::remove(QDir::homePath()+"/.config/omadials/config.json");
        Backend backend; Theme theme(state.path());
        QQmlApplicationEngine engine;
        engine.rootContext()->setContextProperty("backend", &backend);
        engine.rootContext()->setContextProperty("desktopTheme", &theme);
        engine.load(QUrl("qrc:/qml/Main.qml"));
        QVERIFY(!engine.rootObjects().isEmpty());
        QObject *root = engine.rootObjects().first();
        auto window = qobject_cast<QQuickWindow*>(root); QVERIFY(window);
        auto pages = root->findChild<QObject*>("pages"); QVERIFY(pages);
        QVERIFY(QTest::qWaitForWindowExposed(window));
        QFile dump(QString("sweep-%1-controls.txt").arg(themeName)); QVERIFY(dump.open(QIODevice::WriteOnly));
        std::function<void(QQuickItem*,int)> walk = [&](QQuickItem *item, int page) {
            if (!item->isVisible()) return;
            auto *a = QAccessible::queryAccessibleInterface(item);
            const QString name = a ? a->text(QAccessible::Name) : QString();
            if (!name.isEmpty() && (item->inherits("QQuickAbstractButton") || item->inherits("QQuickComboBox") || item->inherits("QQuickSlider") || item->inherits("QQuickTextField")))
                dump.write(QString("%1\t%2\t%3\n").arg(page).arg(item->metaObject()->className(),name).toUtf8());
            for (auto *child : item->childItems()) walk(child,page);
        };
        for (int w : {1200, 720}) {
            window->resize(w,3200); QTest::qWait(150);
            for (int i=0;i<5;++i) {
                pages->setProperty("currentIndex",i); QTest::qWait(150);
                QVERIFY(window->grabWindow().save(QString("sweep-%1-%2-page-%3.png").arg(themeName).arg(w).arg(i)));
                if (w == 1200) walk(window->contentItem(),i);
            }
        }
        // Writes: drive each control the way a click does, then read the saved value back.
        auto *store = root->findChild<QObject*>("configStore"); QVERIFY(store);
        auto value = [&](const QString &path) {
            QQmlExpression e(engine.rootContext(),store,QString("JSON.stringify(value('%1'))").arg(path));
            return e.evaluate().toString();
        };
        auto named = [&](const QString &name) -> QQuickItem* {
            std::function<QQuickItem*(QQuickItem*)> find = [&](QQuickItem *item) -> QQuickItem* {
                if (!item->isVisible()) return nullptr;
                auto *a = QAccessible::queryAccessibleInterface(item);
                if (a && a->text(QAccessible::Name) == name && (item->inherits("QQuickAbstractButton") || item->inherits("QQuickComboBox") || item->inherits("QQuickSlider"))) return item;
                for (auto *child : item->childItems()) if (auto *found = find(child)) return found;
                return nullptr;
            };
            return find(window->contentItem());
        };
        QFile log(QString("sweep-%1-writes.txt").arg(themeName)); QVERIFY(log.open(QIODevice::WriteOnly));
        struct Step { int page; QString name; QString op; QVariant arg; QString path; QString expect; };
        const QList<Step> steps = {
            {0,"Top left","click",{},"corner","\"top-left\""}, {0,"Bottom left","click",{},"corner","\"bottom-left\""},
            {0,"Large","click",{},"size","\"L\""}, {0,"Normal","click",{},"size","\"M\""},
            {0,"3 rings","click",{},"tabStyle","\"rings3\""}, {0,"2 rings and a knob","click",{},"tabStyle","\"rings2knob\""},
            {0,"Screens","combo",1,"outputs.mode","\"focused\""}, {0,"Screens","combo",2,"outputs.mode","\"named\""},
            {0,"shot:screens","",{},"",""}, {0,"Screens","combo",0,"outputs.mode","\"all\""},
            {0,"Show the tab","combo",2,"cornerIcon.mode","\"never\""}, {0,"Show the tab","combo",1,"cornerIcon.mode","\"onApproach\""},
            {0,"Show the tab","combo",0,"cornerIcon.mode","\"always\""},
            {0,"Above windows","click",{},"cornerIcon.aboveWindows","false"}, {0,"Above windows","click",{},"cornerIcon.aboveWindows","true"},
            {0,"Open when the pointer rests in the corner","click",{},"trigger.push","false"},
            {0,"","",{},"cornerIcon.mode","\"always\""},
            {0,"Open when the pointer rests in the corner","click",{},"trigger.push","true"},
            {0,"Opening delay","slider",300,"trigger.pushDelayMs","300"}, {0,"Opening delay","slider",150,"trigger.pushDelayMs","150"},
            {0,"Tab size","slider",60,"cornerIcon.scale","0.6"}, {0,"Tab size","slider",100,"cornerIcon.scale","1"},
            {0,"Show battery ring","click",{},"cornerIcon.battery","false"}, {0,"Show battery ring","click",{},"cornerIcon.battery","true"},
            {0,"Battery turns red at","slider",15,"readout.lowBatteryPercent","15"}, {0,"Battery turns red at","slider",20,"readout.lowBatteryPercent","20"},
            {1,"Track","combo",1,"ringStyle.track","!\"solid\""}, {1,"Track","combo",0,"ringStyle.track","\"solid\""},
            {1,"Knob","combo",1,"ringStyle.knob","!\"round\""}, {1,"Knob","combo",0,"ringStyle.knob","\"round\""},
            {1,"Thickness","combo",0,"ringStyle.thickness","!\"normal\""}, {1,"Thickness","combo",1,"ringStyle.thickness","\"normal\""},
            {1,"Edit Brightness","click",{},"",""}, {1,"shot:edit","",{},"",""},
            {3,"Close after","combo",0,"behavior.idleTimeoutS","0"}, {3,"Close after","combo",2,"behavior.idleTimeoutS","10"},
            {3,"Close when the pointer leaves","click",{},"behavior.closeOnPointerLeave","false"},
            {3,"Close when the pointer leaves","click",{},"behavior.closeOnPointerLeave","true"},
            {3,"Fan","click",{},"animation.style","\"fan\""}, {3,"Tab morph","click",{},"animation.style","\"morph\""},
            {3,"Speed","slider",1.5,"animation.speed","1.5"}, {3,"Speed","slider",1,"animation.speed","1"},
            {3,"Bounce","slider",0.2,"animation.bounce","0.2"}, {3,"Bounce","slider",0.06,"animation.bounce","0.06"},
            {3,"Fine control when you drag away from the ring","click",{},"dialInteraction.fineEnabled","false"},
            {3,"Fine control when you drag away from the ring","click",{},"dialInteraction.fineEnabled","true"},
            {3,"Snap to 0, 25, 50, 75 and 100 %","click",{},"dialInteraction.snap","false"},
            {3,"Snap to 0, 25, 50, 75 and 100 %","click",{},"dialInteraction.snap","true"},
            {3,"Volume can go above 100 %","click",{},"options.volume.maxPercent","150"},
            {3,"Volume can go above 100 %","click",{},"options.volume.maxPercent","100"},
            {3,"Animations","click",{},"gameMode.animations","true"}, {3,"Animations","click",{},"gameMode.animations","false"},
            {3,"Blur","click",{},"gameMode.blur","true"}, {3,"Blur","click",{},"gameMode.blur","false"},
            {3,"Shadows","click",{},"gameMode.shadows","true"}, {3,"Shadows","click",{},"gameMode.shadows","false"},
            {3,"Window gaps become 0","click",{},"gameMode.gapsIn","null"}, {3,"","",{},"gameMode.gapsOut","null"},
            {3,"Window gaps become 0","click",{},"gameMode.gapsIn","0"},
            {4,"Corner works when the tab is hidden","click",{},"trigger.tapZone","false"},
            {4,"Corner works when the tab is hidden","click",{},"trigger.tapZone","true"},
        };
        window->resize(1200,3200);
        int failures = 0;
        for (const Step &step : steps) {
            if (pages->property("currentIndex").toInt() != step.page) { pages->setProperty("currentIndex",step.page); QTest::qWait(150); }
            if (step.name.startsWith("shot:")) { QTest::qWait(150); window->grabWindow().save(QString("sweep-%1-%2.png").arg(themeName,step.name.mid(5))); continue; }
            if (!step.op.isEmpty()) {
                QQuickItem *item = named(step.name);
                if (!item) { log.write(QString("MISSING\t%1\n").arg(step.name).toUtf8()); ++failures; continue; }
                if (step.op == "click") { if (item->property("checkable").toBool()) QMetaObject::invokeMethod(item,"toggle"); QMetaObject::invokeMethod(item,"clicked"); }
                else if (step.op == "combo") { item->setProperty("currentIndex",step.arg); QMetaObject::invokeMethod(item,"activated",Q_ARG(int,step.arg.toInt())); }
                else if (step.op == "slider") { item->setProperty("value",step.arg); QMetaObject::invokeMethod(item,"moved"); }
                QTest::qWait(60);
            }
            if (step.path.isEmpty()) continue;
            const QString got = value(step.path);
            const bool ok = step.expect.startsWith("!") ? got != step.expect.mid(1) : got == step.expect;
            if (!ok) ++failures;
            log.write(QString("%1\t%2\t%3\t%4\n").arg(ok ? "OK" : "FAIL",step.name,step.path,got).toUtf8());
        }
        log.close();
        QCOMPARE(failures,0);
        // The app follows a theme switch: Omarchy replaces the theme folder, it does not edit the file.
        if (themeName != "white") {
            QDir(state.filePath("theme")).removeRecursively(); QDir().mkpath(state.filePath("theme"));
            QVERIFY(QFile::copy("/usr/share/omarchy/themes/white/colors.toml",state.filePath("theme/colors.toml")));
            QTRY_COMPARE(theme.colors().value("background").toString(),QString("#ffffff"));
            pages->setProperty("currentIndex",0); QTest::qWait(400);
            window->resize(1200,1100); QTest::qWait(150);
            QVERIFY(window->grabWindow().save(QString("sweep-%1-switched-to-white.png").arg(themeName)));
        }
    }
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
        QVERIFY(eval("config.dials.some(function(d) { return d.id==='mic' })").toBool());
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
