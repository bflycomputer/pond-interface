#pragma once

#include <QDBusConnection>
#include <QDBusMessage>
#include <QObject>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

class Battery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool present READ present NOTIFY changed)
    Q_PROPERTY(int percentage READ percentage NOTIFY changed)

public:
    explicit Battery(QObject *parent = nullptr) : QObject(parent) {
        auto bus = QDBusConnection::systemBus();
        bus.connect(service, path, properties, "PropertiesChanged", this, SLOT(propertiesChanged(QString, QVariantMap)));
        auto call = QDBusMessage::createMethodCall(service, path, properties, "GetAll");
        call << QStringLiteral("org.freedesktop.UPower.Device");
        bus.callWithCallback(call, this, SLOT(update(QVariantMap)));
    }
    bool present() const { return m_device.value("IsPresent").toBool() && m_device.value("Type").toUInt() == 2; }
    int percentage() const { return qRound(m_device.value("Percentage").toDouble()); }

signals:
    void changed();

private slots:
    void propertiesChanged(const QString &, const QVariantMap &values) { update(values); }
    void update(const QVariantMap &values) {
        m_device.insert(values);
        emit changed();
    }

private:
    static constexpr auto service = "org.freedesktop.UPower";
    static constexpr auto path = "/org/freedesktop/UPower/devices/DisplayDevice";
    static constexpr auto properties = "org.freedesktop.DBus.Properties";
    QVariantMap m_device;
};
