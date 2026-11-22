// AedwenOS window decoration -- see aedwendecoration.h.
#include "aedwendecoration.h"

#include <KDecoration3/DecoratedWindow>
#include <KDecoration3/DecorationSettings>
#include <KDecoration3/DecorationShadow>

#include <KColorScheme>
#include <KConfigGroup>
#include <KSharedConfig>

#include <QIcon>
#include <QPainter>
#include <QPainterPath>

#include <algorithm>
#include <cmath>
#include <map>
#include <tuple>

namespace Aedwen
{

namespace
{
// scripts/generate-aurorae-theme.py
constexpr qreal TitleHeight = 48;
constexpr qreal ButtonSize = 32;
constexpr qreal ButtonSpacing = 4;
// design (Settings window): title bar padding 0 8 0 16, 12 px from the app
// icon to the title -- with the icon centred in a 32 px menu button cell
constexpr qreal EdgeLeft = 10;  // menu button: its 20 px icon starts 16 px in
constexpr qreal EdgeRight = 8;
constexpr qreal TitleGap = 6;   // icon edge (6 px inside its cell) + 6 = 12
constexpr qreal IconSize = 20;
constexpr qreal Outline = 2;
constexpr qreal ResizeBorder = 6; // grab area outside the ring, not drawn
constexpr int ShadowPad = 24;
constexpr int ShadowDy = 8;
constexpr qreal ShadowAlpha = 0.30;
constexpr qreal InactiveShadow = 0.6;
constexpr qreal HoverRadius = 10; // Expressive ctl-hover-r
constexpr int HoverDuration = 180;  // Theme.durShort

// The design's window is `border-radius: r-win` with a 2 px border inside it:
// the ring's outer edge has radius r-win, the content r-win - 2. KWin clips
// the window to r-win - 2 and the ring is drawn just outside it, so the
// outline lands exactly on r-win.
qreal radiusFor(bool expressive)
{
    return (expressive ? 16 : 12) - Outline;
}

QColor withAlpha(QColor c, qreal a)
{
    c.setAlphaF(std::clamp(c.alphaF() * a, 0.0, 1.0));
    return c;
}

// Signed distance from p to a w x h rounded rect at (x, y), radius r;
// negative inside.
qreal roundedRectSdf(qreal px, qreal py, qreal x, qreal y, qreal w, qreal h, qreal r)
{
    const qreal qx = std::abs(px - (x + w / 2)) - (w / 2 - r);
    const qreal qy = std::abs(py - (y + h / 2)) - (h / 2 - r);
    return std::hypot(std::max(qx, 0.0), std::max(qy, 0.0)) + std::min(std::max(qx, qy), 0.0) - r;
}

// The shadow and the 2 px ring, as a nine-patch of a small template window:
// corners hold the whole corner (radius plus the downward offset), the 2 px
// middle row and column stretch along the straight edges. One image per
// radius, focus state and ring colour, shared by every window
// (KDecoration's advice).
//
// The ring lives here rather than in KDecoration's BorderOutline: KWin 6.8
// drops the outline's corner arcs whenever the decoration also has a shadow,
// leaving four straight bars. In the shadow it sits where KWin would put the
// outline -- just outside the frame -- and its corners follow the window's.
std::shared_ptr<KDecoration3::DecorationShadow> shadowFor(qreal r, bool active, const QColor &ring)
{
    static std::map<std::tuple<int, bool, QRgb>, std::shared_ptr<KDecoration3::DecorationShadow>> cache;
    const auto key = std::make_tuple(int(r), active, ring.rgba());
    if (auto it = cache.find(key); it != cache.end())
        return it->second;

    const int corner = int(r) + ShadowDy;      // template window: corner, 2 px, corner
    const int win = 2 * corner + 2;
    const int size = win + 2 * ShadowPad;
    const qreal scale = active ? 1.0 : InactiveShadow;
    const qreal ringAlpha = ring.alphaF();
    QImage img(size, size, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    for (int y = 0; y < size; ++y) {
        auto *line = reinterpret_cast<QRgb *>(img.scanLine(y));
        for (int x = 0; x < size; ++x) {
            const qreal px = x + 0.5, py = y + 0.5;
            // nothing under the window itself (antialiased like KWin's clip)
            const qreal edge = roundedRectSdf(px, py, ShadowPad, ShadowPad, win, win, r);
            const qreal cover = std::clamp(edge + 0.5, 0.0, 1.0);
            if (cover <= 0)
                continue;
            const qreal d = roundedRectSdf(px, py - ShadowDy, ShadowPad, ShadowPad, win, win, r);
            const qreal t = std::clamp(d / (ShadowPad + 4), 0.0, 1.0);
            const qreal shadow = (d <= 0 ? ShadowAlpha : ShadowAlpha * std::pow(1 - t, 2.2)) * scale * cover;
            // ring: 0 <= edge <= Outline, antialiased on both sides
            const qreal ra = ringAlpha * cover * std::clamp(Outline + 0.5 - edge, 0.0, 1.0);
            const qreal a = ra + shadow * (1 - ra);
            line[x] = qRgba(qRound(ring.redF() * ra * 255), qRound(ring.greenF() * ra * 255),
                            qRound(ring.blueF() * ra * 255), qRound(a * 255));
        }
    }
    auto shadow = std::make_shared<KDecoration3::DecorationShadow>();
    shadow->setShadow(img);
    shadow->setPadding(QMarginsF(ShadowPad, ShadowPad, ShadowPad, ShadowPad));
    shadow->setInnerShadowRect(QRectF(ShadowPad + corner, ShadowPad + corner, 2, 2));
    cache.emplace(key, shadow);
    return shadow;
}
} // namespace

// --- Decoration -------------------------------------------------------------

Decoration::Decoration(QObject *parent, const QVariantList &args)
    : KDecoration3::Decoration(parent, args)
{
}

Decoration::~Decoration() = default;

bool Decoration::maximized() const
{
    return window()->isMaximized();
}

void Decoration::readConfig()
{
    auto config = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    config->reparseConfiguration();
    // The AedwenOS baseline schemes are "AedwenOS<Accent><Dark|Light>",
    // Expressive ones end in "Expressive"; any other scheme gets Expressive.
    const QString scheme = config->group(QStringLiteral("General")).readEntry("ColorScheme", QString());
    m_expressive = !(scheme.startsWith(QLatin1String("AedwenOS")) && !scheme.endsWith(QLatin1String("Expressive")));
    m_highContrast = config->group(QStringLiteral("AedwenOS")).readEntry("Contrast", QString()) == QLatin1String("high");
    m_animationFactor = std::max(0.0, config->group(QStringLiteral("KDE")).readEntry("AnimationDurationFactor", 1.0));
}

bool Decoration::init()
{
    readConfig();

    auto *w = window();
    auto s = settings();

    connect(w, &KDecoration3::DecoratedWindow::widthChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::maximizedChanged, this, [this] {
        updateBorders();
        updateShadow();
        updateLayout();
    });
    connect(w, &KDecoration3::DecoratedWindow::activeChanged, this, [this] {
        updateBorders();
        updateShadow();
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::paletteChanged, this, [this] {
        // a colour scheme switch can also switch Expressive and baseline
        readConfig();
        updateBorders();
        updateShadow();
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::captionChanged, this, [this] { update(); });
    connect(w, &KDecoration3::DecoratedWindow::iconChanged, this, [this] { update(); });
    connect(s.get(), &KDecoration3::DecorationSettings::fontChanged, this, [this] { update(); });
    connect(s.get(), &KDecoration3::DecorationSettings::decorationButtonsLeftChanged, this, &Decoration::updateButtons);
    connect(s.get(), &KDecoration3::DecorationSettings::decorationButtonsRightChanged, this, &Decoration::updateButtons);

    updateButtons();
    updateBorders();
    updateShadow();
    return true;
}

void Decoration::updateButtons()
{
    delete m_left;
    delete m_right;
    // the groups read ButtonsOnLeft / ButtonsOnRight from the settings
    m_left = new KDecoration3::DecorationButtonGroup(KDecoration3::DecorationButtonGroup::Position::Left, this, &Button::create);
    m_right = new KDecoration3::DecorationButtonGroup(KDecoration3::DecorationButtonGroup::Position::Right, this, &Button::create);
    m_left->setSpacing(ButtonSpacing);
    m_right->setSpacing(ButtonSpacing);
    updateLayout();
}

void Decoration::updateBorders()
{
    const bool max = maximized();
    setBorders(QMarginsF(0, TitleHeight, 0, 0));
    setResizeOnlyBorders(max ? QMarginsF() : QMarginsF(ResizeBorder, 0, ResizeBorder, ResizeBorder));
    setBorderRadius(max ? KDecoration3::BorderRadius() : KDecoration3::BorderRadius(radiusFor(m_expressive)));
}

void Decoration::updateShadow()
{
    if (maximized()) {
        setShadow(nullptr);
        return;
    }
    const bool active = window()->isActive();
    const QPalette pal = window()->palette();
    // High contrast: opaque ring (highlight when active, text colour when not)
    const QColor ring = m_highContrast
        ? (active ? pal.color(QPalette::Active, QPalette::Highlight) : pal.color(QPalette::Active, QPalette::WindowText))
        : active ? withAlpha(pal.color(QPalette::Active, QPalette::Highlight), 0.65)
                 : withAlpha(pal.color(QPalette::Active, QPalette::WindowText), 0.16);
    setShadow(shadowFor(radiusFor(m_expressive), active, ring));
}

void Decoration::updateLayout()
{
    const qreal width = size().width();
    setTitleBar(QRectF(0, 0, width, TitleHeight));
    const qreal y = (TitleHeight - ButtonSize) / 2;
    if (m_left)
        m_left->setPos(QPointF(EdgeLeft, y));
    if (m_right)
        m_right->setPos(QPointF(width - EdgeRight - m_right->geometry().width(), y));
    update();
}

void Decoration::paint(QPainter *painter, const QRectF &repaintArea)
{
    auto *w = window();
    const QPalette pal = w->palette();
    const bool active = w->isActive();
    const QRectF bar(0, 0, size().width(), TitleHeight);

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(Qt::NoPen);
    // [WM] activeBackground / inactiveBackground: surface-container (design
    // --sc) focused, surface unfocused (scripts/generate-colorscheme.py)
    const auto group = active ? KDecoration3::ColorGroup::Active : KDecoration3::ColorGroup::Inactive;
    painter->setBrush(w->color(group, KDecoration3::ColorRole::TitleBar));
    if (maximized()) {
        painter->drawRect(bar);
    } else {
        // KWin clips to borderRadius as well; rounding here keeps the
        // corners right should a compositor path skip the clip
        const qreal r = radiusFor(m_expressive);
        QPainterPath path;
        path.addRoundedRect(QRectF(0, 0, bar.width(), bar.height() + r), r, r);
        painter->setClipRect(bar);
        painter->drawPath(path);
        painter->setClipping(false);
    }

    // title: after the left buttons, before the right ones, left-aligned
    const qreal left = m_left && m_left->geometry().width() > 0 ? m_left->geometry().right() + TitleGap : 16;
    const qreal right = m_right && m_right->geometry().width() > 0 ? m_right->geometry().left() - TitleGap : bar.width() - 16;
    const QRectF titleRect(left, 0, std::max(0.0, right - left), TitleHeight);
    if (titleRect.width() > 0 && titleRect.intersects(repaintArea)) {
        QFont font = settings()->font();
        painter->setFont(font);
        painter->setPen(w->color(group, KDecoration3::ColorRole::Foreground));
        const QString caption = painter->fontMetrics().elidedText(w->caption(), Qt::ElideRight, int(titleRect.width()));
        painter->drawText(titleRect, Qt::AlignLeft | Qt::AlignVCenter | Qt::TextSingleLine, caption);
    }
    painter->restore();

    if (m_left)
        m_left->paint(painter, repaintArea);
    if (m_right)
        m_right->paint(painter, repaintArea);
}

// --- Button -----------------------------------------------------------------

Button::Button(KDecoration3::DecorationButtonType type, Decoration *decoration, QObject *parent)
    : KDecoration3::DecorationButton(type, decoration, parent)
{
    setGeometry(QRectF(0, 0, ButtonSize, ButtonSize));
    m_hover.setStartValue(0.0);
    m_hover.setEndValue(1.0);
    m_hover.setDuration(qRound(HoverDuration * decoration->animationFactor()));
    m_hover.setEasingCurve(QEasingCurve::OutCubic);
    connect(&m_hover, &QVariantAnimation::valueChanged, this, [this] { update(); });
    connect(this, &KDecoration3::DecorationButton::hoveredChanged, this, [this](bool hovered) {
        m_hover.setDirection(hovered ? QAbstractAnimation::Forward : QAbstractAnimation::Backward);
        if (m_hover.duration() == 0) { // no animations: paint() follows isHovered()
            update();
            return;
        }
        if (m_hover.state() != QAbstractAnimation::Running)
            m_hover.start();
    });
    connect(this, &KDecoration3::DecorationButton::pressedChanged, this, [this] { update(); });
    connect(this, &KDecoration3::DecorationButton::checkedChanged, this, [this] { update(); });
    connect(this, &KDecoration3::DecorationButton::enabledChanged, this, [this] { update(); });
    connect(decoration->window(), &KDecoration3::DecoratedWindow::activeChanged, this, [this] { update(); });
}

KDecoration3::DecorationButton *Button::create(KDecoration3::DecorationButtonType type, KDecoration3::Decoration *decoration, QObject *parent)
{
    auto *d = qobject_cast<Decoration *>(decoration);
    if (!d)
        return nullptr;
    switch (type) {
    case KDecoration3::DecorationButtonType::Menu:
    case KDecoration3::DecorationButtonType::Minimize:
    case KDecoration3::DecorationButtonType::Maximize:
    case KDecoration3::DecorationButtonType::Close:
        return new Button(type, d, parent);
    default:
        // the design has no glyphs for the rest (keep above, shade, ...);
        // they stay in the window menu
        return nullptr;
    }
}

void Button::paint(QPainter *painter, const QRectF &repaintArea)
{
    if (!isVisible() || !geometry().intersects(repaintArea))
        return;
    auto *d = static_cast<Decoration *>(decoration());
    auto *w = d->window();
    const QPalette pal = w->palette();
    const bool active = w->isActive();
    const bool close = type() == KDecoration3::DecorationButtonType::Close;
    const bool menu = type() == KDecoration3::DecorationButtonType::Menu;
    const QRectF cell = geometry();

    // hover progress; without animations it follows the state directly
    qreal t = m_hover.duration() == 0 ? (isHovered() ? 1.0 : 0.0) : m_hover.currentValue().toReal();
    if (isPressed())
        t = 1.0;
    if (!isEnabled())
        t = 0.0;

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(Qt::NoPen);

    const qreal radius = d->expressive() ? ButtonSize / 2 + (HoverRadius - ButtonSize / 2) * t : ButtonSize / 2;

    // rest: the button colour (none behind the app icon)
    if (!menu) {
        const qreal restAlpha = !isEnabled() ? (active ? 0.6 : 0.4) : (active ? 1.0 : 0.6);
        if (t < 1) {
            // design: --sc-highest, the scheme's [Colors:Button] BackgroundAlternate
            const QColor rest = KColorScheme(QPalette::Active, KColorScheme::Button).background(KColorScheme::AlternateBackground).color();
            painter->setBrush(withAlpha(rest, restAlpha * (1 - t)));
            painter->drawRoundedRect(cell, radius, radius);
        }
    }
    // hover / press: accent, or the negative colour for close
    if (t > 0) {
        QColor accent = close ? w->color(KDecoration3::ColorGroup::Warning, KDecoration3::ColorRole::Foreground)
                              : pal.color(QPalette::Active, QPalette::Highlight);
        if (!accent.isValid())
            accent = QColor(0xff, 0x9b, 0x93);
        const qreal a = isPressed() ? (close ? 0.5 : 0.34) : (close ? 0.35 : 0.22);
        painter->setBrush(withAlpha(accent, a * t));
        painter->drawRoundedRect(cell, radius, radius);
    }

    if (menu) {
        const QRectF iconRect(cell.center() - QPointF(IconSize / 2, IconSize / 2), QSizeF(IconSize, IconSize));
        w->icon().paint(painter, iconRect.toRect());
    } else {
        qreal glyphAlpha = 1.0;
        if (!isEnabled())
            glyphAlpha = active ? 0.3 : 0.25;
        else if (!active && t == 0)
            glyphAlpha = 0.62;
        QPen pen(withAlpha(pal.color(QPalette::Active, QPalette::WindowText), glyphAlpha), 2);
        pen.setCapStyle(Qt::RoundCap);
        pen.setJoinStyle(Qt::RoundJoin);
        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);
        paintGlyph(painter, cell);
    }
    painter->restore();
}

// Material Symbols Rounded look, the 32 px cells of generate-aurorae-theme.py
void Button::paintGlyph(QPainter *painter, const QRectF &cell) const
{
    painter->translate(cell.topLeft());
    auto line = [painter](qreal x1, qreal y1, qreal x2, qreal y2) {
        painter->drawLine(QPointF(x1, y1), QPointF(x2, y2));
    };
    auto poly = [painter](std::initializer_list<QPointF> pts) {
        painter->drawPolyline(std::data(pts), int(pts.size()));
    };
    switch (type()) {
    case KDecoration3::DecorationButtonType::Minimize:
        line(10.5, 16, 21.5, 16);
        break;
    case KDecoration3::DecorationButtonType::Maximize:
        if (isChecked()) { // close_fullscreen: arrows in
            line(11, 21, 15, 17);
            line(17, 15, 21, 11);
            poly({{11.5, 17}, {15, 17}, {15, 20.5}});
            poly({{17, 11.5}, {17, 15}, {20.5, 15}});
        } else { // open_in_full: arrows out
            line(13, 19, 19, 13);
            poly({{15, 10.5}, {21.5, 10.5}, {21.5, 17}});
            poly({{10.5, 15}, {10.5, 21.5}, {17, 21.5}});
        }
        break;
    case KDecoration3::DecorationButtonType::Close:
        line(11, 11, 21, 21);
        line(21, 11, 11, 21);
        break;
    default:
        break;
    }
}

} // namespace Aedwen
