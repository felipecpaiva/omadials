pragma ComponentBehavior: Bound
import QtQuick
import "../logic/Glyphs.js" as Glyphs
import "../logic/Geometry.js" as Geometry
import "../logic/Layout.js" as Layout

Item {
    id: readout
    required property var theme
    required property var model
    required property string size
    required property string corner
    required property real fanRadius
    required property real screenWidth
    required property real screenHeight
    property double elapsed: 0
    readonly property var boxes: Geometry.textBoxes(screenWidth,screenHeight,corner)
    readonly property var layout: model.textLayout(size,measure,{width:screenWidth,height:screenHeight},corner,fanRadius,elapsed)
    function measure(text,width) {
        return width === Layout.SHORT_WIDTH ? shortMeasure.implicitHeight : width === Layout.LONG_WIDTH ? longMeasure.implicitHeight : noticeMeasure.implicitHeight
    }
    Text { id: shortMeasure; visible: false; width: Layout.SHORT_WIDTH; text: readout.model.status; wrapMode: Text.Wrap; font.family: readout.theme.font; font.pixelSize: 12; lineHeightMode: Text.FixedHeight; lineHeight: Layout.LINE }
    Text { id: longMeasure; visible: false; width: Layout.LONG_WIDTH; text: readout.model.status; wrapMode: Text.Wrap; font.family: readout.theme.font; font.pixelSize: 12; lineHeightMode: Text.FixedHeight; lineHeight: Layout.LINE }
    Text { id: noticeMeasure; visible: false; width: Layout.NOTICE_WIDTH; text: readout.model.status; wrapMode: Text.Wrap; font.family: readout.theme.font; font.pixelSize: 12; lineHeightMode: Text.FixedHeight; lineHeight: Layout.LINE }
    Connections { target: readout.model; function onStatusAtChanged() { readout.elapsed = 0; noticeTimer.restart() } }
    Timer { id: noticeTimer; interval: Layout.NOTICE_HOLD; onTriggered: readout.elapsed = Layout.NOTICE_HOLD }
    Text {
        readonly property var b: readout.boxes.readout
        x: b.x; y: readout.corner.indexOf("top") >= 0 ? b.y+Layout.TARGET+Layout.LINE+Layout.GAP : readout.screenHeight-Layout.INSET-Layout.TARGET-Layout.LINE-Layout.GAP-readout.layout.batteryFont
        width: b.width; height: readout.layout.batteryFont
        visible: !readout.layout.hideBattery && !!readout.model.battery
        text: readout.model.battery ? readout.model.battery.valueText : ""
        color: readout.theme.text; font.family: readout.theme.font; font.pixelSize: readout.layout.batteryFont; lineHeightMode: Text.FixedHeight; lineHeight: readout.layout.batteryFont
        wrapMode: Text.Wrap
    }
    Text {
        readonly property var b: Geometry.batteryLineBox(readout.screenWidth,readout.screenHeight,readout.corner)
        x: b.x; y: b.y; width: b.width
        visible: readout.layout.batteryLine && !!readout.model.battery
        text: readout.model.batteryLine
        color: readout.theme.secondary; font.family: readout.theme.font; font.pixelSize: 12; wrapMode: Text.Wrap
    }
    Rectangle {
        readonly property var b: readout.layout.status
        x: b.x; y: b.y; width: b.width; height: statusCopy.implicitHeight+8
        visible: !!readout.model.status && (readout.layout.mode !== "notice" || readout.layout.noticeVisible)
        color: readout.layout.mode === "notice" ? readout.theme.surface : Qt.alpha(readout.theme.surface,0)
        radius: 8
        Text {
            id: statusCopy; width: parent.width; text: readout.model.status
            color: readout.model.statusError ? readout.theme.warn : readout.theme.text
            font.family: readout.theme.font; font.pixelSize: 12; lineHeightMode: Text.FixedHeight; lineHeight: Layout.LINE
            wrapMode: Text.Wrap
        }
    }
    ReadoutButton {
        theme: readout.theme; box: readout.boxes.profile
        text: readout.model.profile ? readout.model.profile.valueText : "Power profile"
        onClicked: if (readout.model.profile) readout.model.openDetail(readout.model.profile)
    }
    ReadoutButton {
        theme: readout.theme; box: readout.boxes.gear; text: Glyphs.glyph("settings")
        onClicked: { readout.model.activity(); readout.model.settingsRequested() }
    }
}
