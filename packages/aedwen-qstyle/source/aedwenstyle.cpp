#include "aedwenstyle.h"

#include <KColorScheme>

#include <QAction>
#include <QFontDatabase>
#include <QMenu>
#include <QPainter>
#include <QPainterPath>
#include <QStyleFactory>
#include <QStyleOptionMenuItem>

namespace
{
// System Surfaces design, section 03 (Context menus)
constexpr int ItemHeight = 36;
constexpr int GroupPadding = 4; // inside each group, around its items
constexpr int GroupGap = 2; // between groups, where separator lines were
constexpr int SeparatorHeight = GroupPadding + GroupGap + GroupPadding;
constexpr int HeaderHeight = 32; // section title (QMenu::addSection)
constexpr int OuterRadius = 16;
constexpr int InnerRadius = 4;
constexpr int ItemRadius = 12;
constexpr int IconSize = 20;
constexpr int ItemPaddingLeft = 12;
constexpr int ItemPaddingRight = 10;
constexpr int Spacing = 12;
constexpr int TrailSize = 18;
constexpr int MinimumWidth = 244;
constexpr qreal DisabledOpacity = 0.38;
constexpr qreal StateLayer = 0.08;

QColor alpha(QColor c, qreal a)
{
    c.setAlphaF(a);
    return c;
}

// a + (b - a) * t, as Theme.mix in org.aedwen.ui
QColor mix(const QColor &a, const QColor &b, qreal t)
{
    return QColor::fromRgbF(a.redF() + (b.redF() - a.redF()) * t,
                            a.greenF() + (b.greenF() - a.greenF()) * t,
                            a.blueF() + (b.blueF() - a.blueF()) * t);
}

struct MenuColors {
    QColor container; // surface-container-high
    QColor fg; // on-surface
    QColor fgMuted; // on-surface-variant (shortcuts, section titles)
    QColor checked; // tertiary container
    QColor onChecked;
};

MenuColors menuColors(const QPalette &palette)
{
    const QPalette::ColorGroup group = palette.currentColorGroup() == QPalette::Disabled ? QPalette::Disabled : QPalette::Active;
    MenuColors c;
    c.container = palette.color(group, QPalette::Button);
    c.fg = palette.color(group, QPalette::Text);
    c.fgMuted = alpha(c.fg, 0.62);
    // AedwenOS colour schemes carry the tertiary container in ForegroundNeutral
    // (scripts/generate-colorscheme.py); Theme.qml reads it the same way.
    c.checked = KColorScheme(group, KColorScheme::View).foreground(KColorScheme::NeutralText).color();
    c.onChecked = mix(c.fg, c.checked, 0.15);
    return c;
}

// Rounded rect with separate top and bottom corner radii.
QPainterPath roundedRect(const QRectF &r, qreal top, qreal bottom)
{
    QPainterPath p;
    p.moveTo(r.left() + top, r.top());
    p.lineTo(r.right() - top, r.top());
    p.quadTo(r.right(), r.top(), r.right(), r.top() + top);
    p.lineTo(r.right(), r.bottom() - bottom);
    p.quadTo(r.right(), r.bottom(), r.right() - bottom, r.bottom());
    p.lineTo(r.left() + bottom, r.bottom());
    p.quadTo(r.left(), r.bottom(), r.left(), r.bottom() - bottom);
    p.lineTo(r.left(), r.top() + top);
    p.quadTo(r.left(), r.top(), r.left() + top, r.top());
    p.closeSubpath();
    return p;
}

QFont shortcutFont(const QFont &base)
{
    QFont f = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    f.setPointSizeF(base.pointSizeF() > 0 ? base.pointSizeF() * 0.86 : f.pointSizeF());
    return f;
}

QFont headerFont(const QFont &base)
{
    QFont f = base;
    f.setWeight(QFont::DemiBold);
    if (base.pointSizeF() > 0)
        f.setPointSizeF(base.pointSizeF() * 0.9);
    return f;
}

// Material-style strokes in an 18 px box, so nothing depends on an icon font
void drawCheck(QPainter *p, const QRectF &box, const QColor &color)
{
    QPainterPath path;
    path.moveTo(box.left() + 3.5, box.top() + 9.5);
    path.lineTo(box.left() + 7.5, box.top() + 13.5);
    path.lineTo(box.left() + 14.5, box.top() + 5.5);
    p->setPen(QPen(color, 2.0, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    p->setBrush(Qt::NoBrush);
    p->drawPath(path);
}

void drawChevron(QPainter *p, const QRectF &box, const QColor &color, bool rtl)
{
    QPainterPath path;
    const qreal a = rtl ? 11.0 : 7.0, b = rtl ? 6.5 : 11.5;
    path.moveTo(box.left() + a, box.top() + 4.5);
    path.lineTo(box.left() + b, box.top() + 9.0);
    path.lineTo(box.left() + a, box.top() + 13.5);
    p->setPen(QPen(color, 2.0, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
    p->setBrush(Qt::NoBrush);
    p->drawPath(path);
}

QStyle *breeze()
{
    QStyle *base = QStyleFactory::create(QStringLiteral("Breeze"));
    return base ? base : QStyleFactory::create(QStringLiteral("Fusion"));
}
} // namespace

AedwenStyle::AedwenStyle()
    : QProxyStyle(breeze())
{
}

void AedwenStyle::polish(QWidget *widget)
{
    QProxyStyle::polish(widget);
    if (qobject_cast<QMenu *>(widget)) {
        // the gaps between groups show what's behind the menu
        widget->setAttribute(Qt::WA_TranslucentBackground, true);
        widget->setAutoFillBackground(false);
    }
}

void AedwenStyle::unpolish(QWidget *widget)
{
    QProxyStyle::unpolish(widget);
}

void AedwenStyle::drawPrimitive(PrimitiveElement element, const QStyleOption *option, QPainter *painter, const QWidget *widget) const
{
    const QMenu *menu = qobject_cast<const QMenu *>(widget);
    if (menu && element == PE_FrameMenu)
        return;
    if (!menu || element != PE_PanelMenu) {
        QProxyStyle::drawPrimitive(element, option, painter, widget);
        return;
    }

    // Split the visible items into groups at separators and draw each group
    // as its own block: outer corners 16, inner corners 4.
    struct Span {
        int top, bottom;
    };
    QList<Span> groups;
    int top = 0;
    bool hasItems = false;
    const auto actions = menu->actions();
    for (QAction *action : actions) {
        if (!action->isVisible())
            continue;
        const QRect geometry = menu->actionGeometry(action);
        if (geometry.isEmpty())
            continue; // collapsed separator
        if (action->isSeparator()) {
            if (hasItems)
                groups.append({top, geometry.top() + GroupPadding});
            top = geometry.top() + GroupPadding + GroupGap;
            hasItems = false;
        } else {
            hasItems = true;
        }
    }
    if (hasItems || groups.isEmpty())
        groups.append({top, menu->height()});

    const MenuColors colors = menuColors(option->palette);
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    painter->setPen(Qt::NoPen);
    painter->setBrush(colors.container);
    for (int i = 0; i < groups.size(); ++i) {
        const qreal t = i == 0 ? OuterRadius : InnerRadius;
        const qreal b = i == groups.size() - 1 ? OuterRadius : InnerRadius;
        const QRectF r(0, groups[i].top, menu->width(), groups[i].bottom - groups[i].top);
        painter->drawPath(roundedRect(r, std::min(t, r.height() / 2), std::min(b, r.height() / 2)));
    }
    painter->restore();
}

void AedwenStyle::drawControl(ControlElement element, const QStyleOption *option, QPainter *painter, const QWidget *widget) const
{
    if (element == CE_MenuEmptyArea && qobject_cast<const QMenu *>(widget))
        return;
    const auto *item = qstyleoption_cast<const QStyleOptionMenuItem *>(option);
    if (element != CE_MenuItem || !item) {
        QProxyStyle::drawControl(element, option, painter, widget);
        return;
    }

    const MenuColors colors = menuColors(option->palette);
    const QRect r = option->rect;
    const bool rtl = option->direction == Qt::RightToLeft;

    // separator: the gap itself is left empty by the group blocks; a
    // section title sits at the top of the next group
    if (item->menuItemType == QStyleOptionMenuItem::Separator) {
        if (!item->text.isEmpty()) {
            painter->save();
            painter->setFont(headerFont(item->font));
            painter->setPen(colors.fgMuted);
            const QRect header = r.adjusted(ItemPaddingLeft, SeparatorHeight, -ItemPaddingLeft, 0);
            const QString text = QFontMetrics(painter->font()).elidedText(item->text, Qt::ElideRight, header.width());
            painter->drawText(header, Qt::AlignVCenter | (rtl ? Qt::AlignRight : Qt::AlignLeft) | Qt::TextSingleLine, text);
            painter->restore();
        }
        return;
    }
    if (item->menuItemType != QStyleOptionMenuItem::Normal && item->menuItemType != QStyleOptionMenuItem::DefaultItem
        && item->menuItemType != QStyleOptionMenuItem::SubMenu) {
        QProxyStyle::drawControl(element, option, painter, widget);
        return;
    }

    const bool enabled = option->state & State_Enabled;
    const bool selected = enabled && (option->state & State_Selected);
    const bool checked = item->checkType != QStyleOptionMenuItem::NotCheckable && item->checked;
    const QColor fg = checked ? colors.onChecked : colors.fg;

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing);
    if (!enabled)
        painter->setOpacity(DisabledOpacity);

    if (checked || selected) {
        QColor fill = checked ? colors.checked : alpha(colors.fg, StateLayer);
        if (checked && selected)
            fill = mix(colors.checked, colors.fg, StateLayer);
        painter->setPen(Qt::NoPen);
        painter->setBrush(fill);
        painter->drawRoundedRect(QRectF(r), ItemRadius, ItemRadius);
    }

    // lay out left-to-right, then mirror for RTL
    auto place = [&](int x, int w) {
        QRect box(x, r.top(), w, r.height());
        return rtl ? QStyle::visualRect(Qt::RightToLeft, r, box) : box;
    };
    int x = r.left() + ItemPaddingLeft;
    int right = r.right() - ItemPaddingRight + 1;

    // icon column (only when some item in the menu has an icon)
    if (item->maxIconWidth > 0) {
        if (!item->icon.isNull()) {
            const QIcon::Mode mode = !enabled ? QIcon::Disabled : selected ? QIcon::Active : QIcon::Normal;
            const QPixmap pixmap = item->icon.pixmap(QSize(IconSize, IconSize), painter->device()->devicePixelRatioF(), mode,
                                                     checked ? QIcon::On : QIcon::Off);
            const QRect box = place(x, IconSize);
            const QRect target(box.left(), box.top() + (box.height() - IconSize) / 2, IconSize, IconSize);
            painter->drawPixmap(target, pixmap);
        }
        x += IconSize + Spacing;
    }

    // trailing chevron / check
    const QRect trail = place(right - TrailSize, TrailSize);
    const QRectF trailBox(trail.left(), trail.top() + (trail.height() - TrailSize) / 2.0, TrailSize, TrailSize);
    if (item->menuItemType == QStyleOptionMenuItem::SubMenu)
        drawChevron(painter, trailBox, fg, rtl);
    else if (checked)
        drawCheck(painter, trailBox, fg);
    right -= TrailSize + Spacing;

    // "Label\tShortcut"
    QString label = item->text;
    QString shortcut;
    const int tab = label.indexOf(QLatin1Char('\t'));
    if (tab >= 0) {
        shortcut = label.mid(tab + 1);
        label.truncate(tab);
    }
    if (!shortcut.isEmpty()) {
        const QFont font = shortcutFont(item->font);
        const int w = QFontMetrics(font).horizontalAdvance(shortcut);
        painter->setFont(font);
        painter->setPen(checked ? fg : colors.fgMuted);
        painter->drawText(place(right - w, w), Qt::AlignVCenter | Qt::AlignRight | Qt::TextSingleLine, shortcut);
        right -= w + Spacing;
    }

    QFont font = item->font;
    if (item->menuItemType == QStyleOptionMenuItem::DefaultItem)
        font.setWeight(QFont::DemiBold);
    painter->setFont(font);
    painter->setPen(fg);
    int flags = Qt::AlignVCenter | Qt::TextSingleLine | (rtl ? Qt::AlignRight : Qt::AlignLeft);
    flags |= proxy()->styleHint(SH_UnderlineShortcut, option, widget) ? Qt::TextShowMnemonic : Qt::TextHideMnemonic;
    const QRect text = place(x, std::max(0, right - x));
    painter->drawText(text, flags, QFontMetrics(font).elidedText(label, Qt::ElideRight, text.width(), Qt::TextShowMnemonic));

    painter->restore();
}

QSize AedwenStyle::sizeFromContents(ContentsType type, const QStyleOption *option, const QSize &size, const QWidget *widget) const
{
    const auto *item = qstyleoption_cast<const QStyleOptionMenuItem *>(option);
    if (type != CT_MenuItem || !item)
        return QProxyStyle::sizeFromContents(type, option, size, widget);

    if (item->menuItemType == QStyleOptionMenuItem::Separator) {
        if (item->text.isEmpty())
            return QSize(1, SeparatorHeight); // a 0 width would read as "hidden" to QMenu
        const int w = QFontMetrics(headerFont(item->font)).horizontalAdvance(item->text) + 2 * ItemPaddingLeft;
        return QSize(w, SeparatorHeight + HeaderHeight);
    }
    if (item->menuItemType != QStyleOptionMenuItem::Normal && item->menuItemType != QStyleOptionMenuItem::DefaultItem
        && item->menuItemType != QStyleOptionMenuItem::SubMenu)
        return QProxyStyle::sizeFromContents(type, option, size, widget);

    QString label = item->text;
    QString shortcut;
    const int tab = label.indexOf(QLatin1Char('\t'));
    if (tab >= 0) {
        shortcut = label.mid(tab + 1);
        label.truncate(tab);
    }
    QFont font = item->font;
    if (item->menuItemType == QStyleOptionMenuItem::DefaultItem)
        font.setWeight(QFont::DemiBold);
    int w = ItemPaddingLeft + QFontMetrics(font).horizontalAdvance(label) + Spacing + TrailSize + ItemPaddingRight;
    if (item->maxIconWidth > 0)
        w += IconSize + Spacing;
    if (!shortcut.isEmpty())
        w += 2 * Spacing + QFontMetrics(shortcutFont(item->font)).horizontalAdvance(shortcut);
    return QSize(std::max(w, MinimumWidth - 2 * GroupPadding), ItemHeight);
}

int AedwenStyle::pixelMetric(PixelMetric metric, const QStyleOption *option, const QWidget *widget) const
{
    switch (metric) {
    case PM_MenuPanelWidth:
    case PM_MenuDesktopFrameWidth:
        return 0;
    case PM_MenuHMargin:
    case PM_MenuVMargin:
        return GroupPadding;
    case PM_SubMenuOverlap:
        return -GroupPadding; // a 4 px gap beside the parent menu
    default:
        return QProxyStyle::pixelMetric(metric, option, widget);
    }
}

int AedwenStyle::styleHint(StyleHint hint, const QStyleOption *option, const QWidget *widget, QStyleHintReturn *returnData) const
{
    if (hint == SH_Menu_SupportsSections)
        return true;
    return QProxyStyle::styleHint(hint, option, widget, returnData);
}
