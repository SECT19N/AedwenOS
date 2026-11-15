// Registers the AedwenOS decoration with KWin (kwinrc
// [org.kde.kdecoration2] library=org.kde.aedwen).
#include "aedwendecoration.h"

#include <KPluginFactory>

K_PLUGIN_FACTORY_WITH_JSON(AedwenDecorationFactory, "aedwen.json", registerPlugin<Aedwen::Decoration>();)

#include "aedwenplugin.moc"
