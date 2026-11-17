pragma ComponentBehavior: Bound
import QtQuick
import "../logic/ValueMap.js" as ValueMap

FocusScope {
    id: target
    required property var control
    required property var model
    required property var box
    x: box.x; y: box.y; width: Math.max(48,box.width); height: Math.max(48,box.height)
    activeFocusOnTab: true
    Accessible.role: control.kind === "readout" ? Accessible.StaticText : Accessible.Slider
    Accessible.name: control.label + ", " + control.valueText
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu || (event.key === Qt.Key_Return && event.modifiers & Qt.ShiftModifier)) model.openDetail(control)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) { if (control.kind === "readout") model.openDetail(control); else model.action(control,false) }
        else {
            if (control.kind === "readout" || control.availability !== "available") { event.accepted = false; return }
            const names = {}; names[Qt.Key_Up]="ArrowUp"; names[Qt.Key_Right]="ArrowRight"; names[Qt.Key_Down]="ArrowDown"; names[Qt.Key_Left]="ArrowLeft"
            names[Qt.Key_PageUp]="PageUp"; names[Qt.Key_PageDown]="PageDown"; names[Qt.Key_Home]="Home"; names[Qt.Key_End]="End"
            if (!names[event.key]) { event.accepted = false; return }
            control.set(ValueMap.keyboard(control.value,names[event.key],!!(event.modifiers & Qt.ShiftModifier),control.range))
        }
        model.report(control); model.activity(); event.accepted = true
    }
}
