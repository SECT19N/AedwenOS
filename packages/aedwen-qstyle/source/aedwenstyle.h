// Aedwen widget style: Breeze for every widget, except context menus, which
// follow the AedwenOS System Surfaces design (section 03, Context menus):
//
//   - items grouped into rounded surface-container-high blocks; separator
//     lines become 2 px gaps between groups
//   - outer corners 16 px, inner corners 4 px (the connected-button rule)
//   - 36 px items, 20 px icon, shortcut right-aligned in mono and muted
//   - hover = 8 % on-surface state layer, 12 px corners
//   - checked = tertiary-container fill with a trailing check, no checkbox
//   - submenus get a trailing chevron; disabled items at 38 %
//
// Colours come from the active KDE colour scheme (the same roles Theme.qml
// in org.aedwen.ui reads), so menus follow the accent and light/dark.
#pragma once

#include <QProxyStyle>

class AedwenStyle : public QProxyStyle
{
    Q_OBJECT

public:
    AedwenStyle();

    void polish(QWidget *widget) override;
    void unpolish(QWidget *widget) override;

    void drawPrimitive(PrimitiveElement element, const QStyleOption *option, QPainter *painter,
                       const QWidget *widget = nullptr) const override;
    void drawControl(ControlElement element, const QStyleOption *option, QPainter *painter,
                     const QWidget *widget = nullptr) const override;
    QSize sizeFromContents(ContentsType type, const QStyleOption *option, const QSize &size,
                           const QWidget *widget = nullptr) const override;
    int pixelMetric(PixelMetric metric, const QStyleOption *option = nullptr,
                    const QWidget *widget = nullptr) const override;
    int styleHint(StyleHint hint, const QStyleOption *option = nullptr, const QWidget *widget = nullptr,
                  QStyleHintReturn *returnData = nullptr) const override;
};
