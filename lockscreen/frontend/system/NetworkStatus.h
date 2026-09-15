#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <NetworkManagerQt/Manager>

class NetworkStatus : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool wifiConnected READ wifiConnected NOTIFY wifiConnectedChanged)

public:
    explicit NetworkStatus(QObject *parent = nullptr) : QObject(parent) {
        auto *notifier = NetworkManager::notifier();
        connect(notifier, &NetworkManager::Notifier::deviceAdded, this, &NetworkStatus::watchDevices);
        connect(notifier, &NetworkManager::Notifier::deviceRemoved, this, &NetworkStatus::watchDevices);
        connect(notifier, &NetworkManager::Notifier::statusChanged, this, &NetworkStatus::watchDevices);
        connect(notifier, &NetworkManager::Notifier::wirelessEnabledChanged, this, &NetworkStatus::refresh);
        connect(notifier, &NetworkManager::Notifier::wirelessHardwareEnabledChanged, this, &NetworkStatus::refresh);
        watchDevices();
    }
    bool wifiConnected() const { return m_wifiConnected; }

signals:
    void wifiConnectedChanged();

private:
    void watchDevices() {
        for (const auto &connection : std::as_const(m_connections))
            disconnect(connection);
        m_connections.clear();
        for (const auto &device : NetworkManager::networkInterfaces()) {
            if (device->type() == NetworkManager::Device::Wifi)
                m_connections.append(connect(device.data(), &NetworkManager::Device::stateChanged, this, &NetworkStatus::refresh));
        }
        refresh();
    }
    void refresh() {
        bool connected = false;
        if (NetworkManager::isWirelessEnabled() && NetworkManager::isWirelessHardwareEnabled()) {
            for (const auto &device : NetworkManager::networkInterfaces())
                connected |= device->type() == NetworkManager::Device::Wifi
                    && device->state() == NetworkManager::Device::Activated;
        }
        if (m_wifiConnected != connected) {
            m_wifiConnected = connected;
            emit wifiConnectedChanged();
        }
    }
    QList<QMetaObject::Connection> m_connections;
    bool m_wifiConnected = false;
};
