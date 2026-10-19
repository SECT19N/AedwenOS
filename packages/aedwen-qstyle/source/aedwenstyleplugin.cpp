// Registers the "Aedwen" widget style with Qt (kdeglobals [KDE]
// widgetStyle=Aedwen).
#include "aedwenstyle.h"

#include <QStylePlugin>

class AedwenStylePlugin : public QStylePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QStyleFactoryInterface_iid FILE "aedwen.json")

public:
    QStyle *create(const QString &key) override
    {
        if (key.compare(QLatin1String("aedwen"), Qt::CaseInsensitive) == 0)
            return new AedwenStyle;
        return nullptr;
    }
};

#include "aedwenstyleplugin.moc"
