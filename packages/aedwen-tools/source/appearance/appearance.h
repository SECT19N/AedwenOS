// System Settings > Colours & Themes > Appearance (System Surfaces design:
// the Settings window, "Appearance" page).
//
//   Style     Material 3 (baseline) or Expressive
//   Colour    from the wallpaper, an accent preset or a custom hue / hex;
//             theme dark / light / auto; contrast standard / medium / high
//   Details   cursors, icons, fonts, sounds (open their own pages)
//
// Every choice applies at once. Presets at standard contrast use the shipped
// AedwenOS<Seed><Dark|Light>[Expressive] colour schemes; a custom hue or
// another contrast level generates a pair (dark and light) into
// ~/.local/share/color-schemes with /usr/lib/aedwen/generate-colorscheme.py.
// The choice is stored in kdeglobals [AedwenOS], which the shell
// (org.aedwen.config) and this page read back.
//
// Dark / light switching (this page, Quick Settings, or Plasma's automatic
// day / night switch) goes through the AedwenOS global themes, so this page
// keeps user-local copies of them whose colour scheme is the chosen one.
//
// An accent change also recolours the boot splash and Limine menu, through
// a polkit-authorised helper (aedwen-boot-accent), a moment after the last
// change; those show from the next restart.
#pragma once

#include <KQuickConfigModule>
#include <KSharedConfig>
#include <QTimer>
#include <QVariantList>

class AppearanceKcm : public KQuickConfigModule
{
    Q_OBJECT
    Q_PROPERTY(QString variant READ variant NOTIFY stateChanged)
    Q_PROPERTY(QString seed READ seed NOTIFY stateChanged)
    Q_PROPERTY(int hue READ hue NOTIFY stateChanged)
    Q_PROPERTY(QString theme READ theme NOTIFY stateChanged)
    Q_PROPERTY(QString contrast READ contrast NOTIFY stateChanged)
    Q_PROPERTY(QString iconMode READ iconMode NOTIFY stateChanged)
    Q_PROPERTY(bool adjusted READ adjusted NOTIFY stateChanged)
    Q_PROPERTY(QVariantList presets READ presets CONSTANT)
    Q_PROPERTY(QVariantList wallpaperSeeds READ wallpaperSeeds NOTIFY wallpaperSeedsChanged)
    Q_PROPERTY(QVariantList details READ details NOTIFY stateChanged)
    Q_PROPERTY(QString bootStatus READ bootStatus NOTIFY bootStatusChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    AppearanceKcm(QObject *parent, const KPluginMetaData &data);

    QString variant() const { return m_variant; }
    QString seed() const { return m_seed; }
    int hue() const { return m_hue; }
    QString theme() const { return m_theme; }
    QString contrast() const { return m_contrast; }
    QString iconMode() const { return m_iconMode; }
    bool adjusted() const { return m_adjusted; }
    QVariantList presets() const;
    QVariantList wallpaperSeeds() const { return m_wallpaperSeeds; }
    QVariantList details() const;
    QString bootStatus() const { return m_bootStatus; }
    QString error() const { return m_error; }

    Q_INVOKABLE void setVariant(const QString &variant);
    Q_INVOKABLE void setSeed(const QString &seed);
    Q_INVOKABLE void setCustomHue(int hue);
    // "#rrggbb" or "rrggbb"; returns false if it isn't a colour
    Q_INVOKABLE bool setHex(const QString &hex);
    Q_INVOKABLE void setTheme(const QString &theme);
    Q_INVOKABLE void setContrast(const QString &contrast);
    // "themed" (tinted to the seed) or "colour" (each app keeps its own hue)
    Q_INVOKABLE void setIconMode(const QString &mode);
    Q_INVOKABLE void openModule(const QString &module);

    // Role colours for an accent hue in the current theme and variant:
    // primary, onPrimary, pc, onPc, secC, onSecC, seed (the swatch colour)
    Q_INVOKABLE QVariantMap colorsFor(int hue) const;
    Q_INVOKABLE QString hexFor(int hue) const;

    void load() override;

Q_SIGNALS:
    void stateChanged();
    void wallpaperSeedsChanged();
    void bootStatusChanged();
    void errorChanged();

private:
    int seedHue() const;
    bool isDark() const;
    QString schemeName(bool dark) const;
    bool generateSchemes();
    void apply();
    void writeLookAndFeel(const QString &id, const QString &base, const QString &scheme);
    void updateWallpaperSeeds();
    void runBootHelper();
    void setError(const QString &e);

    KSharedConfig::Ptr m_globals;
    QString m_variant = QStringLiteral("expressive");
    QString m_seed = QStringLiteral("violet");
    int m_hue = 295;
    QString m_theme = QStringLiteral("dark");
    QString m_contrast = QStringLiteral("standard");
    QString m_iconMode = QStringLiteral("themed");
    bool m_adjusted = false;
    QVariantList m_wallpaperSeeds;
    QString m_bootStatus;
    QString m_error;
    QTimer m_bootTimer;
    int m_bootHue = -1;
    bool m_bootRunning = false;
};
