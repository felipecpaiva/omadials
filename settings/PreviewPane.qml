pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../views" as Views
import "../vm" as Models
import "../logic/Geometry.js" as Geometry

ColumnLayout {
    id: previewPane
    required property var store
    required property var registry
    required property var theme
    // The model is isolated so the preview never opens or writes to the real fan.
    property Component fanComponent: null
    property string highlightId: ""
    readonly property var cap: Geometry.capacity(store.config.size,
        Quickshell.screens.length ? Math.min(Quickshell.screens[0].width, Quickshell.screens[0].height) : 1080)
    readonly property real previewRadius: cap.R
    readonly property var radii: Geometry.ringRadii(previewRadius, Math.min(previewModel.rings.length, cap.rings))
    Models.FanModel {
        id: previewModel
        open: true
        registry: previewPane.registry
        config: previewPane.store.config
    }
    signal showOnScreen()
    signal editRequested(string id, bool toggle)
    Text { text: "Live preview (60%)"; color: previewPane.theme.text; font.family: previewPane.theme.font }
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: previewPane.previewRadius * 0.6
        clip: true
        Loader {
            id: previewLoader
            sourceComponent: previewPane.fanComponent || realFan
            scale: 0.6
            width: previewPane.previewRadius; height: width
            transformOrigin: Item.TopLeft
        }
        PreviewTargets {
            scale: 0.6; transformOrigin: Item.TopLeft
            width: previewPane.previewRadius; height: width
            theme: previewPane.theme; corner: previewPane.store.config.corner
            rings: previewModel.rings; toggles: previewModel.toggles; radii: previewPane.radii
            toggleRadius: previewPane.cap.toggleRadius; highlightId: previewPane.highlightId
            onPicked: (id, toggle) => previewPane.editRequested(id, toggle)
        }
    }
    HelpText { theme: previewPane.theme; text: "Click a ring or a toggle to edit it." }
    Component {
        id: realFan
        Views.Fan {
            enabled: false
            width: previewPane.previewRadius; height: width
            size: previewPane.store.config.size
            toggleRadius: previewPane.cap.toggleRadius
            theme: previewPane.theme; model: previewModel
            corner: previewPane.store.config.corner
            fanRadius: previewPane.previewRadius
            radii: previewPane.radii
            origin: Qt.point(corner.indexOf("right") >= 0 ? width : 0, corner.indexOf("top") >= 0 ? 0 : height)
            screenWidth: width; screenHeight: height
        }
    }
    SettingsButton { theme: previewPane.theme; text: "Show the corner"; onClicked: previewPane.showOnScreen() }
}
