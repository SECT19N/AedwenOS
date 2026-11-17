// aedwen-welcome's backend: the seed colour (the same kdeglobals [AedwenOS]
// keys and colour schemes the Appearance settings use), the once-only
// marker, and launching the things its cards point at.
#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class Controller : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString userName READ userName CONSTANT)
    Q_PROPERTY(QString seed READ seed NOTIFY seedChanged)
    Q_PROPERTY(QVariantList seeds READ seeds CONSTANT)
    Q_PROPERTY(bool showOnStartup READ showOnStartup WRITE setShowOnStartup NOTIFY showOnStartupChanged)

public:
    explicit Controller(QObject *parent = nullptr);

    QString userName() const;
    QString seed() const { return m_seed; }
    QVariantList seeds() const;
    bool showOnStartup() const { return m_show; }
    void setShowOnStartup(bool show);

    // Switch the whole desktop to a seed colour: [AedwenOS] Seed/Hue, the
    // matching colour scheme, then the cursor and icon themes follow it.
    Q_INVOKABLE void setSeed(const QString &seed);
    // Closing the window: the app has had its one showing, unless the user
    // set "Show on startup" themselves, in which case that choice stands.
    Q_INVOKABLE void finish();
    Q_INVOKABLE void launch(const QString &program, const QStringList &args = {});

    // True on the live ISO or once the user has said they're done.
    static bool suppressed();
    static QString markerPath();

Q_SIGNALS:
    void seedChanged();
    void showOnStartupChanged();

private:
    QString m_seed;
    bool m_show = true;
    bool m_touched = false;
};
