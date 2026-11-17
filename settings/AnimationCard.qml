pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Ui as Ui
import "../logic/Labels.js" as Labels
import "../logic/MotionPreview.js" as MotionPreview
// Style as moving pictures, Speed, and Bounce for the spring styles. Previews move only while the panel is open.
SettingsCard {
    id: animationCard
    required property var store
    property bool active: true
    readonly property string style: store.value("animation.style") ?? "morph"
    readonly property real speed: store.value("animation.speed") ?? 1
    readonly property real bounce: store.value("animation.bounce") ?? 0.06
    title: "Animation"
    HelpText { theme: animationCard.theme; text: "Style" }
    Flow {
        Layout.fillWidth: true
        Layout.preferredHeight: childrenRect.height  // Flow.implicitHeight is read-only
        spacing: 6
        Repeater {
            model: MotionPreview.STYLES
            ColumnLayout {
                id: option
                required property string modelData
                readonly property bool selected: animationCard.style === modelData
                HoverHandler { id: hover }
                MotionPicture {
                    Layout.alignment: Qt.AlignHCenter
                    theme: animationCard.theme; styleKey: option.modelData
                    speed: animationCard.speed; bounce: animationCard.bounce
                    active: animationCard.active; hovered: hover.hovered; selected: option.selected
                }
                SettingsButton {
                    Layout.preferredWidth: 120
                    theme: animationCard.theme; text: Labels.label(option.modelData); selected: option.selected
                    onClicked: animationCard.store.set("animation.style", option.modelData)
                }
            }
        }
    }
    HelpText { theme: animationCard.theme; text: Labels.description(animationCard.style) }
    Repeater {
        model: [{key:"speed",label:"Speed",hint:"How fast the corner opens and closes.",min:0.5,max:2,step:0.1},
                {key:"bounce",label:"Bounce",hint:"How much the spring styles overshoot before they settle.",min:0,max:0.35,step:0.01}]
        RowLayout {
            id: sliderRow
            required property var modelData
            readonly property real current: sliderRow.modelData.key === "speed" ? animationCard.speed : animationCard.bounce
            visible: modelData.key === "speed" || MotionPreview.SPRINGS.indexOf(animationCard.style) >= 0
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                Text { text: sliderRow.modelData.label; color: animationCard.theme.text; font.family: animationCard.theme.font }
                HelpText { theme: animationCard.theme; text: sliderRow.modelData.hint }
            }
            HelpText { Layout.fillWidth: false; Layout.preferredWidth: 40; theme: animationCard.theme; text: sliderRow.modelData.key === "speed" ? slider.liveValue.toFixed(1) + "x" : slider.liveValue.toFixed(2) }
            Ui.PanelSlider {
                id: slider
                Layout.preferredWidth: 170
                minimum: sliderRow.modelData.min; maximum: sliderRow.modelData.max; step: sliderRow.modelData.step
                value: sliderRow.current
                trackColor: animationCard.theme.track; fillColor: animationCard.theme.accent; knobColor: animationCard.theme.text; tickColor: animationCard.theme.surface
                Accessible.name: sliderRow.modelData.label
                onReleased: v => animationCard.store.set("animation." + sliderRow.modelData.key, Math.round(v * 100) / 100)
            }
        }
    }
    HelpText { theme: animationCard.theme; text: "Every style opens out of the corner tab and closes back into it. Reduced motion uses Minimal." }
}
