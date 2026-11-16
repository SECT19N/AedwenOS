// OKLCH <-> sRGB, the same math as scripts/palette_lib.py (o(),
// srgb_hex_to_oklch) and the design's palette(): the KCM previews colours
// with it, so the swatches match the colour schemes it applies.
#pragma once

#include <QColor>
#include <cmath>

namespace Oklch
{
inline QColor toColor(double L, double C, double H)
{
    C = std::min(C, 0.2);
    const double a = C * std::cos(H * M_PI / 180), b = C * std::sin(H * M_PI / 180);
    const double l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    const double m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    const double s_ = L - 0.0894841775 * a - 1.2914855480 * b;
    const double l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    auto srgb = [](double c) {
        c = std::clamp(c, 0.0, 1.0);
        c = c <= 0.0031308 ? 12.92 * c : 1.055 * std::pow(c, 1 / 2.4) - 0.055;
        return int(std::lround(std::clamp(c, 0.0, 1.0) * 255));
    };
    return QColor(srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
                  srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
                  srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s));
}

struct LCH {
    double L, C, H;
};

inline LCH fromColor(const QColor &c)
{
    auto lin = [](double v) { return v <= 0.04045 ? v / 12.92 : std::pow((v + 0.055) / 1.055, 2.4); };
    const double r = lin(c.redF()), g = lin(c.greenF()), b = lin(c.blueF());
    const double l = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const double m = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const double s = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    const double L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    const double A = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    const double B = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    double H = std::atan2(B, A) * 180 / M_PI;
    if (H < 0)
        H += 360;
    return {L, std::hypot(A, B), H};
}
} // namespace Oklch
