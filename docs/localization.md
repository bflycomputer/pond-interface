# Localization

Pond stores translations in readable UTF-8 JSON dictionaries. The shared
`Pond.Localization` module owns the English fallback translator, selected translator, user preference,
and engine refreshes. It has no dependency on Quickshell and is also imported by
SDDM. Translation catalogs are embedded in the module; all consumers import the
same installed module instead of repository-relative singleton copies.

## Build

Install Qt 6.11+ development packages (Core, Qml, Quick),
CMake, a C++ compiler, and KF6 NetworkManagerQt. On Arch these include `qt6-base`,
`qt6-declarative`, `cmake`, and `networkmanager-qt`.

```sh
cmake -S . -B build
cmake --build build -j4
```

Check graphical startup and the interface in a Pond Wayland session after building.

## Authoring and translation

Edit `translations/en.json` and `translations/fr.json` directly. Each file is a
flat dictionary from stable message IDs to text, with two-space indentation:

```json
{
  "pond.cancel": "Cancel",
  "notifications.count": {
    "one": "%n notification",
    "other": "%n notifications"
  }
}
```

Use the same IDs in every language. Keep IDs stable when editing wording and give
different meanings different IDs. Add new messages to both English and French.
In QML, use `qsTrId("pond.cancel")`, `.arg()` with `%1`/`%2` for parameters,
and `qsTrId("notifications.count", count)` with `%n` for counts. Escape line breaks
as `\n`. English uses `one` at 1; French uses it at 0 and 1. The small loader
currently handles these two-form plural rules; languages with other plural rules
need a loader extension before shipping.

To start another language, copy `en.json` to a locale-named file such as `de.json`
and translate its values. Missing entries fall back to English; the shipped
English and French catalogs must be complete. Language choices are discovered
from the embedded filenames and displayed with native language names.

Validate before building:

```sh
python3 tools/translations.py
```

The validator checks JSON structure, duplicate IDs, referenced messages (including
helper error/status IDs), plural forms, and placeholders. Helpers return stable
error IDs and parameters; `detail` is diagnostic text, not UI text. Never use
translated text as a status value or comparison.

Rebuild after editing a catalog; reconfigure and build after adding a language.
CMake embeds the JSON directly in `Pond.Localization`. There is no extraction or
catalog-compilation step, and no Qt Linguist tools are needed. Shared catalogs and
the loader live at the repository root because the shell, lock screen, SDDM login
screen, and screenshot UI all use them. Shell-only helpers stay under `shell/`.

## Preferences and locale

`Localization.useUserPreferences()` enables the session preference and watches
`$XDG_CONFIG_HOME/pond-interface/locale.json` (default `~/.config`). Its existing
format is preserved: `{"language":"system"}`, `"en"`, or `"fr"`. A successful
`setPreference(code)` atomically persists and immediately applies it; failure
returns false, exposes `errorCode`, and keeps the prior selection. Other session
processes observe changes, including creation of a previously missing directory.

The SDDM entry point calls `useSystemLocale()`: it never reads/writes user
preferences. System language variants resolve through Qt's language preferences
and available base catalogs, finally falling back to English. Regional formatting
follows the system locale in system mode and the selected locale for overrides.
Dates, times and numbers use Qt formatting, not language-specific branches.

The illustrated manual and its SVG tooltips use localized artwork resolved by
`Localization.asset(Qt.resolvedUrl("path/to/original.svg"))`. Put a translated
file with the same name in a sibling language directory, for example
`shell/assets/manual/fr/manual.svg` or `shell/assets/manual/de/manual.svg`.
The resolver checks the effective language, then its parent language codes
(`fr_CA` → `fr`), and finally returns the original English file. Missing artwork
falls back independently for each file, without attempting to load missing URLs.
Local files and Qt resources are supported. Selection updates immediately when
the language changes; no QML change is needed when adding another language's SVGs.
Keep the SVG dimensions and section positions identical across languages because
the manual's clipping and hover regions share the same coordinates.

Edit localized artwork directly in its SVG files. The ordinary JSON catalogs do
not change text inside these SVGs. Interactive controls and
accessible QML labels continue to use the catalogs. Externally supplied
application/device names, media metadata and notification content retain their
original text.

## Installation, session testing, and rollback

System packages use `cmake --install build --prefix /usr`. This installs the native
QML modules and catalogs together with shell, lockscreen, screenshot, and wallpaper
runtime files. SDDM uses the standard system Qt QML import path. Installing only
QML files without their matching native module is unsupported.

For a reversible user deployment, stage into a new release directory:

```sh
python3 tools/stage-session.py build "$HOME/.local/share/pond-interface/releases/native-qt"
qs -p "$HOME/.local/share/pond-interface/releases/native-qt/share/pond-interface/shell"
```

The staging command prepends a Quickshell environment pragma giving that release's
native-module search path to both shell and lockscreen entry points. It does not
activate the release. SDDM is a separate system deployment; it is not affected by
the user's named shell override.

After startup checks pass, point `~/.config/quickshell/pond-shell` to the staged
shell and start `qs -c pond-shell -d`. Verify its IPC and settings before stopping
the previous instance by its specific PID. Keep the previous symlink target and
release directory. To roll back, restore that target, start its shell, verify it,
and stop only the replacement instance. Existing locale preferences remain
compatible with both implementations. Do not replace an active lock process or
restart a locked session as part of deployment.
