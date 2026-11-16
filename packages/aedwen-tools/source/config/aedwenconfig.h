// AedwenConfig: kdeglobals [AedwenOS] for QML, updated live when the
// Appearance settings page (or anything else) writes it.
//
//   Variant   baseline | expressive   (default expressive)
//   Contrast  standard | medium | high
//   Seed      blue | violet | teal | green | amber | rose | custom
//   Hue       0..359 (the custom accent)
//   Theme     dark | light | auto
#pragma once

#include <KConfigWatcher>
#include <KSharedConfig>
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>

class AedwenConfig : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString variant READ variant NOTIFY changed)
    Q_PROPERTY(QString contrast READ contrast NOTIFY changed)
    Q_PROPERTY(QString seed READ seed NOTIFY changed)
    Q_PROPERTY(int hue READ hue NOTIFY changed)
    Q_PROPERTY(QString theme READ theme NOTIFY changed)

public:
    explicit AedwenConfig(QObject *parent = nullptr);

    QString variant() const;
    QString contrast() const;
    QString seed() const;
    int hue() const;
    QString theme() const;

Q_SIGNALS:
    void changed();

private:
    KConfigGroup group() const;
    KSharedConfig::Ptr m_config;
    KConfigWatcher::Ptr m_watcher;
};
