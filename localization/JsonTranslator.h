#pragma once
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QTranslator>

// Keep Qt's translation bindings and fallback chain; only the catalog format changes.
class JsonTranslator : public QTranslator {
public:
    bool loadCatalog(const QString &path, const QString &language) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) return false;
        QJsonParseError error;
        const auto document = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.isObject()) return false;
        m_messages = document.object();
        m_french = QLocale(language).language() == QLocale::French;
        return true;
    }

    bool isEmpty() const override { return m_messages.isEmpty(); }

    QString translate(const char *context, const char *sourceText,
                      const char * = nullptr, int n = -1) const override {
        if (context && *context) return {};
        const auto message = m_messages.value(QString::fromUtf8(sourceText));
        QString text;
        if (message.isString()) {
            text = message.toString();
        } else if (message.isObject() && n >= 0) {
            const bool one = m_french ? n < 2 : n == 1;
            text = message.toObject().value(one ? "one" : "other").toString();
        }
        // A null string lets Qt try the English translator for missing/empty entries.
        return text.isEmpty() ? QString() : text;
    }

private:
    QJsonObject m_messages;
    bool m_french = false;
};
