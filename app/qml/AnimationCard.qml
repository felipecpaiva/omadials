import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../logic/Labels.js" as Labels
import "../logic/MotionPreview.js" as MotionPreview
// Style as moving pictures, Speed, and Bounce for the spring styles. A preview moves only while hovered or chosen.
SettingsCard {
    id: animationCard
    required property var store
    readonly property string style: store.value("animation.style") ?? "morph"
    readonly property real speed: store.value("animation.speed") ?? 1
    readonly property real bounce: store.value("animation.bounce") ?? 0.06
    title: qsTr("Animation")
    Label { text: qsTr("Style") }
    GridLayout {
        Layout.fillWidth: true; columns: 3; columnSpacing: 8; rowSpacing: 8
        Repeater {
            model: MotionPreview.STYLES
            Button {
                id: option
                required property string modelData
                Layout.fillWidth: true; Layout.preferredWidth: 1
                implicitHeight: 112
                Accessible.name: Labels.label(modelData)
                highlighted: animationCard.style === modelData
                hoverEnabled: true
                onClicked: animationCard.store.set("animation.style", modelData)
                background: Rectangle { color: option.highlighted ? animationCard.theme.off : animationCard.theme.clear; border.width: option.highlighted ? 2 : 1; border.color: option.highlighted ? animationCard.theme.accent : animationCard.theme.edge; radius: animationCard.theme.radius }
                contentItem: ColumnLayout {
                    MotionPicture {
                        Layout.alignment: Qt.AlignHCenter
                        theme: animationCard.theme; styleKey: option.modelData
                        speed: animationCard.speed; bounce: animationCard.bounce
                        hovered: option.hovered; selected: option.highlighted
                    }
                    Label { Layout.fillWidth: true; text: Labels.label(option.modelData); horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12 }
                }
            }
        }
    }
    Label { Layout.fillWidth: true; text: Labels.description(animationCard.style); color: animationCard.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap }
    Repeater {
        model: [{key:"speed",label:qsTr("Speed"),help:qsTr("How fast the corner opens and closes."),min:0.5,max:2,step:0.1},
                {key:"bounce",label:qsTr("Bounce"),help:qsTr("How much the spring styles overshoot before they settle."),min:0,max:0.35,step:0.01}]
        RowLayout {
            id: sliderRow
            required property var modelData
            readonly property real current: modelData.key === "speed" ? animationCard.speed : animationCard.bounce
            visible: modelData.key === "speed" || MotionPreview.SPRINGS.indexOf(animationCard.style) >= 0
            Layout.fillWidth: true; spacing: 16
            ColumnLayout {
                Layout.fillWidth: true; spacing: 4
                Label { text: sliderRow.modelData.label }
                Label { Layout.fillWidth: true; text: sliderRow.modelData.help; color: animationCard.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap }
            }
            Label { Layout.preferredWidth: 40; text: sliderRow.modelData.key === "speed" ? slider.picked.toFixed(1) + "x" : slider.picked.toFixed(2); color: animationCard.theme.secondary }
            Slider {
                id: slider
                readonly property real picked: Math.round(value / sliderRow.modelData.step) * sliderRow.modelData.step
                Layout.preferredWidth: 190
                from: sliderRow.modelData.min; to: sliderRow.modelData.max; stepSize: sliderRow.modelData.step; snapMode: Slider.NoSnap
                value: sliderRow.current
                Accessible.name: sliderRow.modelData.label
                function save() { animationCard.store.set("animation." + sliderRow.modelData.key, Math.round(picked * 100) / 100) }
                onPressedChanged: if (!pressed) save()
                onMoved: if (!pressed) save()   // arrow keys
            }
        }
    }
    Label { Layout.fillWidth: true; text: qsTr("Every style opens out of the corner tab and closes back into it. Reduced motion uses Minimal."); color: animationCard.theme.secondary; font.pixelSize: 12; wrapMode: Text.WordWrap }
}
