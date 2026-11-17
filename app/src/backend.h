#pragma once
#include <QObject>
#include <QVariantMap>
#include <QFileSystemWatcher>
#include <QProcess>
#include <QTimer>

class Backend : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
public:
    explicit Backend(QObject *parent = nullptr);
    ~Backend() override;
    QString path() const;
    QString error() const { return m_error; }
    QString status() const { return m_status; }
    Q_INVOKABLE QVariantMap resources(const QString &text = {}) const;
    Q_INVOKABLE QVariantMap read();
    Q_INVOKABLE bool write(const QString &text, const QString &expected, bool expectedExists);
    Q_INVOKABLE QString asset(const QString &path);
    Q_INVOKABLE void refreshStatus();
    Q_INVOKABLE void showOnScreen();
signals:
    void fileChanged();
    void errorChanged();
    void statusChanged();
    void statusReceived(const QVariantMap &data);
private:
    void watch();
    void fail(const QString &error);
    void run(bool open);
    QFileSystemWatcher m_watcher;
    QTimer m_poll;
    QProcess m_process;
    QTimer m_timeout;
    QByteArray m_last;
    bool m_exists = false;
    bool m_open = false;
    bool m_timedOut = false;
    QString m_error, m_status = QStringLiteral("Plugin status has not been checked.");
};
