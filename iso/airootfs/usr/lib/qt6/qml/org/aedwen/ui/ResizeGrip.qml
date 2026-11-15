// Resize grip for the shell's popups (Desktop design: launcher, quick
// settings, calendar, notification centre). A 22 px corner with a rounded
// L in the outline colour at 55 % opacity, full on hover; or, for an edge
// (`edges` holding one edge only), a 3 x 36 px bar on a state-layer strip.
//
// Dragging hands the resize to the compositor (QWindow::startSystemResize),
// the same call Plasma's own popup edges use, so the popup keeps the size
// and Plasma remembers it per widget.
//
//   ResizeGrip { edges: Qt.BottomEdge | Qt.RightEdge }   // bottom-right
//   ResizeGrip { edges: Qt.BottomEdge | Qt.LeftEdge }    // bottom-left
//   ResizeGrip { edges: Qt.LeftEdge }                    // left edge bar
import QtQuick
import QtQuick.Shapes

Item {
    id: grip
    property int edges: Qt.BottomEdge | Qt.RightEdge

    readonly property bool onLeft: edges & Qt.LeftEdge
    readonly property bool onRight: edges & Qt.RightEdge
    readonly property bool onTop: edges & Qt.TopEdge
    readonly property bool onBottom: edges & Qt.BottomEdge
    // drawn (and placed) as a corner grip; true for two edges, and settable
    // for one: the calendar's corner grip only resizes sideways (design)
    property bool isCorner: (onLeft || onRight) && (onTop || onBottom)
    // which corner a one-edge corner grip sits in
    property bool cornerBottom: true

    z: 10
    width: isCorner ? 22 : (onLeft || onRight) ? 8 : implicitWidth
    height: isCorner ? 22 : (onTop || onBottom) ? 8 : implicitHeight
    anchors {
        // corners sit 6 px in (design); edge bars span the side, 28 px short
        // of each end so they never cover a corner grip
        left: grip.onLeft || (!grip.isCorner && (grip.onTop || grip.onBottom)) ? parent.left : undefined
        right: grip.onRight || (!grip.isCorner && (grip.onTop || grip.onBottom)) ? parent.right : undefined
        top: grip.onTop || (grip.isCorner && !grip.onBottom && !grip.cornerBottom)
             || (!grip.isCorner && (grip.onLeft || grip.onRight)) ? parent.top : undefined
        bottom: grip.onBottom || (grip.isCorner && !grip.onTop && grip.cornerBottom)
                || (!grip.isCorner && (grip.onLeft || grip.onRight)) ? parent.bottom : undefined
        leftMargin: grip.isCorner ? 6 : (grip.onTop || grip.onBottom) ? 28 : 0
        rightMargin: grip.isCorner ? 6 : (grip.onTop || grip.onBottom) ? 28 : 0
        topMargin: grip.isCorner ? 6 : (grip.onLeft || grip.onRight) ? 28 : 0
        bottomMargin: grip.isCorner ? 6 : (grip.onLeft || grip.onRight) ? 28 : 0
    }

    // edge bar: the design's state layer on hover
    Rectangle {
        anchors.fill: parent
        visible: !grip.isCorner
        color: mouse.containsMouse || mouse.pressed ? Theme.state : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durShort } }
        Rectangle {
            anchors.centerIn: parent
            width: (grip.onLeft || grip.onRight) ? 3 : 36
            height: (grip.onLeft || grip.onRight) ? 36 : 3
            radius: 2
            color: Theme.outline
            opacity: 0.6
        }
    }

    // corner: 10 x 10 box, 3 px border on its two outer sides, 8 px radius
    Shape {
        visible: grip.isCorner
        width: 10
        height: 10
        x: grip.onRight ? parent.width - width - 4 : 4
        y: grip.onBottom || (!grip.onTop && grip.cornerBottom) ? parent.height - height - 4 : 4
        opacity: mouse.containsMouse || mouse.pressed ? 1 : 0.55
        Behavior on opacity { NumberAnimation { duration: Theme.durShort } }
        preferredRendererType: Shape.CurveRenderer
        // mirror one bottom-right L into the other corners
        transform: Scale {
            origin.x: 5
            origin.y: 5
            xScale: grip.onLeft ? -1 : 1
            yScale: grip.onTop || (!grip.onBottom && !grip.cornerBottom) ? -1 : 1
        }
        ShapePath {
            strokeColor: Theme.outline
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.RoundJoin
            // centre line of a 3 px border inside the 10 px box
            startX: 8.5; startY: 0
            PathLine { x: 8.5; y: 2 }
            PathArc { x: 2; y: 8.5; radiusX: 6.5; radiusY: 6.5 }
            PathLine { x: 0; y: 8.5 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: grip.isCorner && (grip.onLeft || grip.onRight) && (grip.onTop || grip.onBottom)
            ? ((grip.onLeft && grip.onBottom) || (grip.onRight && grip.onTop) ? Qt.SizeBDiagCursor : Qt.SizeFDiagCursor)
            : (grip.onLeft || grip.onRight) ? Qt.SizeHorCursor : Qt.SizeVerCursor
        onPressed: ev => {
            const w = grip.Window.window
            ev.accepted = !!w && w.startSystemResize(grip.edges)
        }
    }

    // tooltip text, as in the design
    Accessible.name: qsTr("Drag to resize")
}
