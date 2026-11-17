#include "backend.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QIcon>
#include <QGuiApplication>
#include <QScreen>
#include <QDesktopServices>
#include <QClipboard>
#include <QUrl>
#include <QColor>
#include <QBuffer>
#include <QRegularExpression>

Backend::Backend(QObject *parent) : QObject(parent) {
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] { watch(); emit fileChanged(); });
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { watch(); emit fileChanged(); });
    // Polling also covers a config directory created after launch and missed watch events.
    m_poll.setInterval(500);
    connect(&m_poll, &QTimer::timeout, this, [this] {
        QFile f(path()); bool exists = f.exists();
        if (exists && !f.open(QIODevice::ReadOnly)) { fail(tr("Cannot read config: %1").arg(f.errorString())); return; }
        QByteArray bytes = exists ? f.readAll() : QByteArray();
        if (exists != m_exists || bytes != m_last) { watch(); emit fileChanged(); }
    });
    m_poll.start(); watch();
    m_timeout.setSingleShot(true); m_timeout.setInterval(3000);
    connect(&m_timeout, &QTimer::timeout, this, [this] { m_timedOut = true; m_process.kill(); });
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError e) {
        if (e == QProcess::FailedToStart) { m_timeout.stop(); m_status = tr("Cannot run omarchy-shell: %1").arg(m_process.errorString()); emit statusChanged(); }
    });
    connect(&m_process, &QProcess::finished, this, [this](int code, QProcess::ExitStatus state) {
        m_timeout.stop();
        const QByteArray output = m_process.readAllStandardOutput();
        if (m_timedOut) m_status = tr("omarchy-shell timed out.");
        else if (code != 0 || state != QProcess::NormalExit)
            m_status = tr("omarchy-shell failed: %1").arg(QString::fromUtf8(m_process.readAllStandardError()).trimmed());
        else if (m_open) m_status = tr("Show on screen requested.");
        else {
            QJsonParseError error;
            auto doc = QJsonDocument::fromJson(output, &error);
            if (error.error != QJsonParseError::NoError || (!doc.isObject() || !doc.object().value("controls").isArray())) m_status = tr("Plugin returned invalid status JSON.");
            else { m_status = QString::fromUtf8(doc.toJson(QJsonDocument::Indented)); emit statusReceived(doc.object().toVariantMap()); }
        }
        emit statusChanged();
    });
}
Backend::~Backend() {
    if (m_process.state() != QProcess::NotRunning) {
        m_process.kill(); m_process.waitForFinished(1000);
    }
}
QString Backend::path() const { return QDir::homePath() + "/.config/omadials/config.json"; }
void Backend::fail(const QString &error) { m_error = error; emit errorChanged(); }
void Backend::watch() {
    if (!m_watcher.files().isEmpty()) m_watcher.removePaths(m_watcher.files());
    if (!m_watcher.directories().isEmpty()) m_watcher.removePaths(m_watcher.directories());
    QString dir = QFileInfo(path()).absolutePath();
    while (!QFileInfo::exists(dir) && dir != "/") dir = QFileInfo(dir).absolutePath();
    m_watcher.addPath(dir);
    if (QFileInfo::exists(path())) m_watcher.addPath(path());
}
QVariantMap Backend::read() {
    QFile file(path()); bool exists = file.exists();
    if (exists && !file.open(QIODevice::ReadOnly)) {
        fail(tr("Cannot read config: %1").arg(file.errorString())); return {{"ok",false}};
    }
    QByteArray bytes = exists ? file.readAll() : QByteArray();
    if (exists && file.error() != QFileDevice::NoError) { fail(tr("Cannot read config: %1").arg(file.errorString())); return {{"ok",false}}; }
    m_last = bytes; m_exists = exists;
    fail({});
    return {{"ok",true},{"exists",exists},{"text",QString::fromUtf8(m_last)}};
}
bool Backend::write(const QString &text, const QString &expected, bool expectedExists) {
    auto latest = read();
    if (!latest.value("ok").toBool()) return false;
    if (latest.value("exists").toBool() != expectedExists || (expectedExists && latest.value("text").toString() != expected)) {
        fail(tr("Config changed in another window. Try the edit again.")); return false;
    }
    if (!QDir().mkpath(QFileInfo(path()).absolutePath())) { fail(tr("Cannot create the config directory.")); return false; }
    QSaveFile file(path());
    file.setDirectWriteFallback(false);
    if (!file.open(QIODevice::WriteOnly) || file.write(text.toUtf8()) != text.toUtf8().size() || !file.commit()) {
        fail(tr("Cannot save config: %1").arg(file.errorString())); return false;
    }
    m_last = text.toUtf8(); m_exists = true; watch(); return true;
}
QString Backend::asset(const QString &path) { QFile f(":" + path); if (!f.open(QIODevice::ReadOnly)) { fail(tr("Cannot load bundled resource.")); return {}; } return QString::fromUtf8(f.readAll()); }
QVariantMap Backend::resources(const QString &text) const {
    QStringList themes, icons;
    for (const auto &dir : {QDir::homePath()+"/.config/omarchy/themes", qEnvironmentVariable("OMARCHY_PATH", "/usr/share/omarchy")+"/themes"})
        for (const auto &name : QDir(dir).entryList(QDir::Dirs | QDir::NoDotAndDotDot)) if (!themes.contains(name)) themes.append(name);
    for (const auto &name : {"brightness","volume","mic","wifi","bluetooth","battery","audio-volume-high","network-wireless"})
        if (QIcon::hasThemeIcon(name)) icons.append(name);
    // Retain every valid icon already referenced by the config, not just suggestions.
    auto object = QJsonDocument::fromJson(text.toUtf8()).object();
    QStringList referenced{object.value("cornerIcon").toObject().value("source").toString()};
    auto controls = object.value("controls").toObject();
    for (auto it = controls.begin(); it != controls.end(); ++it)
        referenced.append(it.value().toObject().value("icon").toString());
    for (const auto &name : referenced) if (QIcon::hasThemeIcon(name) && !icons.contains(name)) icons.append(name);
    themes.sort(); icons.sort();
    QStringList screens;
    for (auto *screen : QGuiApplication::screens()) screens.append(screen->name().isEmpty() ? tr("Unnamed screen") : screen->name());
    QFile current(QDir::homePath()+"/.local/state/omarchy/current/theme.name");
    QString currentName;
    if (current.open(QIODevice::ReadOnly)) currentName=QString::fromUtf8(current.readAll()).trimmed();
    QString light, dark;
    for (const auto &name : themes) {
        for (const auto &base : {QDir::homePath()+"/.config/omarchy/themes", qEnvironmentVariable("OMARCHY_PATH", "/usr/share/omarchy")+"/themes"}) {
            QFile colors(base+"/"+name+"/colors.toml");
            if (!colors.open(QIODevice::ReadOnly)) continue;
            auto match=QRegularExpression(R"re(^\s*background\s*=\s*["'](#[a-fA-F0-9]{6})["'])re",QRegularExpression::MultilineOption).match(QString::fromUtf8(colors.readAll()));
            if (!match.hasMatch()) continue;
            QColor background(match.captured(1));
            const bool isLight=background.lightnessF()>.5;
            QString &candidate=isLight ? light : dark;
            if (candidate.isEmpty() || name==currentName) candidate=name;
            break;
        }
    }
    return {{"themes",themes},{"icons",icons},{"screens",screens},{"devices",m_devices},{"lightTheme",light},{"darkTheme",dark}};
}
void Backend::run(bool open) {
    if (m_process.state() != QProcess::NotRunning) return;
    m_open = open; m_timedOut = false;
    m_process.start("omarchy-shell", {"omadials", open ? "open" : "status"});
    m_timeout.start();
}
void Backend::refreshStatus() { run(false); }
void Backend::showOnScreen() { run(true); }

void Backend::openFolder() {
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(QFileInfo(path()).absolutePath()))) fail(tr("Cannot open the settings folder."));
}
void Backend::openReadme() {
    if (!QDesktopServices::openUrl(QUrl("https://github.com/felipecpaiva/omadials#readme"))) fail(tr("Cannot open the README."));
}
void Backend::copyDetails() { QGuiApplication::clipboard()->setText(m_status); }
void Backend::refreshDevices() {
    m_devices.clear();
    // Discovery is explicit and bounded, and never evaluates a shell string.
    auto output=[](const QString &program,const QStringList &args) {
        QProcess process; process.start(program,args);
        if (!process.waitForStarted(200) || !process.waitForFinished(500)) { process.kill(); process.waitForFinished(200); return QString(); }
        return process.exitCode()==0 ? QString::fromUtf8(process.readAllStandardOutput()) : QString();
    };
    for (const auto &line : output("bluetoothctl",{"devices"}).split('\n')) {
        auto match=QRegularExpression("^Device ([0-9A-Fa-f:]{17}) (.+)$").match(line);
        if(match.hasMatch()) m_devices.append(QVariantMap{{"source","bluetoothBattery"},{"key",match.captured(1)},{"name",match.captured(2)}});
    }
    for (const auto &device : output("upower",{"-e"}).split('\n',Qt::SkipEmptyParts)) {
        if (!device.startsWith("/org/freedesktop/UPower/devices/")) continue;
        const auto details=output("upower",{"-i",device});
        if (!QRegularExpression("type:\\s+(pen|tablet)").match(details).hasMatch()) continue;
        auto model=QRegularExpression("model:\\s+([^\n]+)").match(details);
        m_devices.append(QVariantMap{{"source","penBattery"},{"key",device},{"name",model.hasMatch()?model.captured(1).trimmed():tr("Pen battery")}});
    }
    for (const auto &name : QDir("/sys/class/net").entryList(QDir::Dirs|QDir::NoDotAndDotDot))
        if (QFileInfo::exists("/sys/class/net/"+name+"/wireless")) m_devices.append(QVariantMap{{"source","wifiSignal"},{"key",name},{"name",name}});
}

QString Backend::iconUrl(const QString &name) const {
    const auto icon=QIcon::fromTheme(name);
    if (icon.isNull()) return {};
    QByteArray bytes; QBuffer buffer(&bytes); buffer.open(QIODevice::WriteOnly);
    icon.pixmap(32,32).save(&buffer,"PNG");
    return "data:image/png;base64,"+QString::fromLatin1(bytes.toBase64());
}
