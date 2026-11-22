// AedwenOS window decoration (AedwenOS Desktop design, "WINDOWS"): the same
// title bar as the Aurorae themes from scripts/generate-aurorae-theme.py, in
// C++ so KWin can round all four corners. Aurorae has no border radius API:
// it can only paint the top corners round, and the client area underneath
// stays square, so windows had round tops and nearly square bottoms.
//
// Here KWin gets the radius (setBorderRadius) and clips the whole window to
// it, client area included. The 2 px ring is part of the shadow image, just
// outside the frame (see shadowFor() for why not setBorderOutline).
//
// Design: the Settings window of the AedwenOS Surfaces design.
//  - corners: r-win, 16 px (Expressive colour schemes, the default) or 12
//    (the AedwenOS baseline schemes, "AedwenOS<Accent><Dark|Light>.colors"),
//    measured on the outer edge of the 2 px ring
//  - a 48 px title bar in the [WM] title bar colour (surface-container):
//    app icon (window menu) 16 px in, the title 12 px after it, and the
//    buttons from kwinrc ButtonsOnLeft/ButtonsOnRight, 8 px from the edge
//  - 32 px buttons on surface-container-highest; hover/press fills them with the
//    accent (close: the negative colour) and, Expressive only, morphs the
//    circle into a rounded square (ctl-hover-r 10)
//  - ring: accent at 65 % when focused, text at 16 % when not
//  - shadow: 24 px soft shadow, 8 px down, 30 % (60 % of that unfocused)
//  - truly maximised windows (the aedwen-gaps script keeps most windows out
//    of that state) are square, without ring or shadow
//
// Colours follow the window's palette, so light/dark and accent changes need
// no theme switch.
#pragma once

#include <KDecoration3/Decoration>
#include <KDecoration3/DecorationButton>
#include <KDecoration3/DecorationButtonGroup>

#include <QVariantAnimation>

namespace Aedwen
{

class Decoration : public KDecoration3::Decoration
{
    Q_OBJECT

public:
    explicit Decoration(QObject *parent = nullptr, const QVariantList &args = {});
    ~Decoration() override;

    bool init() override;
    void paint(QPainter *painter, const QRectF &repaintArea) override;

    bool expressive() const { return m_expressive; }
    bool maximized() const;
    qreal animationFactor() const { return m_animationFactor; }

private:
    void readConfig();
    void updateLayout();
    void updateBorders();
    void updateShadow();
    void updateButtons();

    KDecoration3::DecorationButtonGroup *m_left = nullptr;
    KDecoration3::DecorationButtonGroup *m_right = nullptr;
    bool m_expressive = true;
    bool m_highContrast = false; // kdeglobals [AedwenOS] Contrast=high
    qreal m_animationFactor = 1.0;
};

class Button : public KDecoration3::DecorationButton
{
    Q_OBJECT

public:
    Button(KDecoration3::DecorationButtonType type, Decoration *decoration, QObject *parent = nullptr);

    static KDecoration3::DecorationButton *create(KDecoration3::DecorationButtonType type,
                                                  KDecoration3::Decoration *decoration, QObject *parent);

    void paint(QPainter *painter, const QRectF &repaintArea) override;

private:
    void paintGlyph(QPainter *painter, const QRectF &cell) const;

    QVariantAnimation m_hover;
};

} // namespace Aedwen
