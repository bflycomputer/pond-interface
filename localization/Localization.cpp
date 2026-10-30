#include "Localization.h"
#include "JsonTranslator.h"
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileSystemWatcher>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPointer>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTimeZone>
#include <QTimer>
#include <QQmlEngine>

// Translators belong to the process, while QML engines come and go on shell reload.
class LocalizationState : public QObject {
    Q_OBJECT
public:
    explicit LocalizationState(QObject *parent) : QObject(parent) {
        for (const auto &file : QDir(":/pond/translations").entryList({"*.json"}, QDir::Files))
            languages.append(file.chopped(5));
        if (!english.loadCatalog(":/pond/translations/en.json", "en"))
            qFatal("Pond's mandatory English translation catalog could not be loaded");
        QCoreApplication::installTranslator(&english);
        path = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/pond-interface/locale.json";
        connect(&watcher, &QFileSystemWatcher::fileChanged, this, &LocalizationState::read);
        connect(&watcher, &QFileSystemWatcher::directoryChanged, this, &LocalizationState::read);
        apply("system");
    }
    ~LocalizationState() override {
        if (QCoreApplication::instance()) {
            QCoreApplication::removeTranslator(&selected);
            QCoreApplication::removeTranslator(&english);
        }
    }
    QString preference = "system", language = "en", error, path;
    QLocale locale;
    QStringList languages;
    bool user = false;
    QList<QPointer<QQmlEngine>> engines;
    QFileSystemWatcher watcher;
    JsonTranslator english, selected;

    void notify() {
        emit changed();
        // Wait until any currently constructed component has finished binding.
        QTimer::singleShot(0, this, [this] {
            engines.removeIf([](const auto &engine) { return engine.isNull(); });
            for (const auto &engine : std::as_const(engines))
                if (engine) engine->retranslate();
        });
    }
    QString resolve(const QString &name) const {
        const QLocale requested(name);
        for (auto candidate : requested.uiLanguages()) {
            candidate.replace('-', '_');
            while (!candidate.isEmpty()) {
                if (languages.contains(candidate)) return candidate;
                const auto cut = candidate.lastIndexOf('_');
                candidate = cut < 0 ? QString() : candidate.left(cut);
            }
        }
        return "en";
    }
    void apply(const QString &value) {
        const auto nextLocale = value == "system" ? QLocale::system() : QLocale(value);
        const auto nextLanguage = resolve(nextLocale.name());
        if (language != nextLanguage) {
            QCoreApplication::removeTranslator(&selected);
            if (nextLanguage != "en" && selected.loadCatalog(":/pond/translations/" + nextLanguage + ".json", nextLanguage))
                QCoreApplication::installTranslator(&selected);
        }
        preference = value;
        language = nextLanguage;
        locale = nextLocale;
        notify();
    }
    void rearm() {
        if (!user) {
            if (!watcher.files().isEmpty()) watcher.removePaths(watcher.files());
            if (!watcher.directories().isEmpty()) watcher.removePaths(watcher.directories());
            return;
        }
        if (QFile::exists(path) && !watcher.files().contains(path)) watcher.addPath(path);
        // The first launch may precede the creation of pond-interface or even XDG_CONFIG_HOME.
        QString directory = QFileInfo(path).absolutePath();
        while (!QDir(directory).exists()) {
            const auto parent = QFileInfo(directory).absolutePath();
            if (parent == directory) break;
            directory = parent;
        }
        for (const auto &oldDirectory : watcher.directories())
            if (oldDirectory != directory) watcher.removePath(oldDirectory);
        if (QDir(directory).exists() && !watcher.directories().contains(directory))
            watcher.addPath(directory);
    }
    void read() {
        if (!user) return;
        QFile file(path);
        QString next = "system";
        if (file.open(QIODevice::ReadOnly)) {
            const auto value = QJsonDocument::fromJson(file.readAll()).object().value("language").toString();
            if (value == "system" || languages.contains(value)) next = value;
        }
        rearm();
        if (next != preference) apply(next);
    }
    bool save(const QString &value) {
        if (!user || (value != "system" && !languages.contains(value))) {
            error = "localization.invalid_language"; notify(); return false;
        }
        QSaveFile file(path);
        const auto data = QJsonDocument(QJsonObject{{"language", value}}).toJson(QJsonDocument::Compact);
        if (!QDir().mkpath(QFileInfo(path).absolutePath()) || !file.open(QIODevice::WriteOnly)
            || file.write(data) != data.size() || !file.commit()) {
            error = "localization.save_failed"; notify(); rearm(); return false;
        }
        error.clear();
        rearm();
        apply(value);
        return true;
    }
signals:
    void changed();
};

Localization *Localization::create(QQmlEngine *engine, QJSEngine *) {
    static QPointer<LocalizationState> state;
    if (!state) state = new LocalizationState(QCoreApplication::instance());
    return new Localization(engine, state);
}
Localization::Localization(QQmlEngine *engine, LocalizationState *state) : m_state(state), m_engine(engine) {
    if (!state->engines.contains(engine)) state->engines.append(engine);
    connect(state, &LocalizationState::changed, this, &Localization::changed);
}
QString Localization::preference() const { return m_state->preference; }
QString Localization::effectiveLanguage() const { return m_state->language; }
QLocale Localization::locale() const { return m_state->locale; }
QString Localization::errorCode() const { return m_state->error; }
QVariantList Localization::availableLanguages() const {
    QVariantList result;
    for (const auto &code : m_state->languages) {
        const QLocale language(code);
        auto label = language.nativeLanguageName();
        if (code.contains('_')) label += " (" + language.nativeTerritoryName() + ")";
        result.append(QVariantMap{{"id", code}, {"label", label}});
    }
    return result;
}
void Localization::useUserPreferences() { m_state->user = true; m_state->read(); }
void Localization::useSystemLocale() {
    m_state->user = false; m_state->rearm(); m_state->apply("system");
}
bool Localization::setPreference(const QString &language) { return m_state->save(language); }
QString Localization::timeZoneName(const QString &id) const {
    m_engine->markCurrentFunctionAsTranslationBinding();
    return QTimeZone(id.toUtf8()).displayName(QDateTime::currentDateTimeUtc(), QTimeZone::LongName, locale());
}
QString Localization::number(double value, int decimals) const {
    m_engine->markCurrentFunctionAsTranslationBinding();
    return locale().toString(value, 'f', decimals);
}
QUrl Localization::asset(const QUrl &fallback) const {
    m_engine->markCurrentFunctionAsTranslationBinding();
    if ((!fallback.isLocalFile() && fallback.scheme() != "qrc") || fallback.fileName().isEmpty())
        return fallback;
    const auto directory = fallback.adjusted(QUrl::RemoveFilename);
    auto language = effectiveLanguage();
    while (!language.isEmpty()) {
        QUrl relative;
        relative.setPath(language + '/' + fallback.fileName());
        const auto candidate = directory.resolved(relative);
        const auto path = candidate.isLocalFile() ? candidate.toLocalFile() : ':' + candidate.path();
        if (QFileInfo(path).isFile()) return candidate;
        const auto cut = language.lastIndexOf('_');
        language = cut < 0 ? QString() : language.left(cut);
    }
    return fallback;
}
#include "Localization.moc"
