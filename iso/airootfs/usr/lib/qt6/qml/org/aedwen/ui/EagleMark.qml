// The AedwenOS eagle (images/eagle.svg, a symbolic SVG), recoloured to
// `color` -- primary by default.
import QtQuick
import org.kde.kirigami as Kirigami

Kirigami.Icon {
    source: Theme.eagle
    isMask: true
    color: Theme.primary
    implicitWidth: 24
    implicitHeight: 24
}
