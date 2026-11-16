#include "aedwenconfig.h"

AedwenConfig::AedwenConfig(QObject *parent)
    : QObject(parent)
    , m_config(KSharedConfig::openConfig(QStringLiteral("kdeglobals")))
    , m_watcher(KConfigWatcher::create(m_config))
{
    connect(m_watcher.data(), &KConfigWatcher::configChanged, this, [this](const KConfigGroup &g) {
        if (g.name() == QLatin1String("AedwenOS")) {
            m_config->reparseConfiguration();
            Q_EMIT changed();
        }
    });
}

KConfigGroup AedwenConfig::group() const
{
    return m_config->group(QStringLiteral("AedwenOS"));
}

QString AedwenConfig::variant() const
{
    return group().readEntry("Variant", QStringLiteral("expressive"));
}

QString AedwenConfig::contrast() const
{
    return group().readEntry("Contrast", QStringLiteral("standard"));
}

QString AedwenConfig::seed() const
{
    return group().readEntry("Seed", QStringLiteral("violet"));
}

int AedwenConfig::hue() const
{
    return group().readEntry("Hue", 295);
}

QString AedwenConfig::theme() const
{
    return group().readEntry("Theme", QStringLiteral("dark"));
}
