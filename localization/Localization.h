#pragma once
#include <QObject>
#include <QLocale>
#include <QUrl>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class QQmlEngine;
class QJSEngine;
class LocalizationState;

class Localization : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(Localization)
    QML_SINGLETON
    Q_PROPERTY(QString preference READ preference NOTIFY changed)
    Q_PROPERTY(QString effectiveLanguage READ effectiveLanguage NOTIFY changed)
    Q_PROPERTY(QLocale locale READ locale NOTIFY changed)
    Q_PROPERTY(QVariantList availableLanguages READ availableLanguages CONSTANT)
    Q_PROPERTY(QString errorCode READ errorCode NOTIFY changed)
public:
    static Localization *create(QQmlEngine *engine, QJSEngine *);
    QString preference() const;
    QString effectiveLanguage() const;
    QLocale locale() const;
    QVariantList availableLanguages() const;
    QString errorCode() const;
    Q_INVOKABLE void useUserPreferences();
    Q_INVOKABLE void useSystemLocale();
    Q_INVOKABLE bool setPreference(const QString &language);
    Q_INVOKABLE QString timeZoneName(const QString &id) const;
    Q_INVOKABLE QString number(double value, int decimals = 0) const;
    Q_INVOKABLE QUrl asset(const QUrl &fallback) const;
signals:
    void changed();
private:
    explicit Localization(QQmlEngine *engine, LocalizationState *state);
    LocalizationState *m_state;
    QQmlEngine *m_engine;
};
