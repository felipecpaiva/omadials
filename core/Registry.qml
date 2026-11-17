import QtQuick
import Quickshell.Io
import "../logic/ConfigSchema.js" as Schema
import "../logic/Layout.js" as Layout

QtObject {
    id: registry
    required property var store
    property bool active: false
    property bool settingsOpen: false
    property var catalog: []
    property var controls: []
    property var objects: ({})
    property int revision: 0
    property CommandRunner runner: CommandRunner { }
    property FileView catalogFile: FileView {
        path: Qt.resolvedUrl("../controls/catalog.json")
        onLoaded: { registry.catalog = JSON.parse(text()); registry.reconcile() }
    }
    property Connections configEvents: Connections {
        target: registry.store
        function onConfigChanged() { registry.reconcile() }
    }
    onSettingsOpenChanged: reconcile()
    onActiveChanged: controls.forEach(c => { c.active = active })
    function byId(id) { return objects[id] || null }
    function entries() {
        const config = store.config
        const items = catalog.map(c => ({id: c.id, source: c.id}))
        ;(config.readoutRings || []).forEach(r => {
            if (!items.some(c => c.id === r.id)) items.push({id: r.id, source: r.source})
        })
        return items
    }
    function reconcile() {
        if (!catalog.length) return
        const config = JSON.parse(JSON.stringify(store.config)), desired = []
        entries().forEach(entry => {
            const meta = catalog.find(c => c.id === entry.source)
            // The corner readout always needs the battery and the power profile, shown as rings or not.
            const shown = config.controls[entry.id]?.shown || entry.id === "powerprofile" || entry.id === "laptopBattery"
            if (!meta || !settingsOpen && !shown) return
            let object = objects[entry.id]
            const parameter = (config.readoutRings || []).find(r => r.id === entry.id) || {}
            if (!object) {
                const component = Qt.createComponent(Qt.resolvedUrl("../controls/" + meta.folder + "/Backend.qml"))
                if (component.status !== Component.Ready) { console.warn(component.errorString()); return }
                object = component.createObject(registry, {runner: runner, controlId: entry.id, kind: meta.kind,
                    label: meta.label, icon: meta.icon, placements: meta.placements})
                if (!object) return
                object.availabilityChanged.connect(() => { registry.revision++ })
                objects[entry.id] = object
            }
            object.options = config.options[entry.id] || {}
            object.parameter = parameter
            object.configuration = config
            object.active = active
            desired.push(object)
        })
        Object.keys(objects).forEach(id => {
            if (!desired.some(c => c.controlId === id)) {
                if (id === "gameMode" && (objects[id].saved || objects[id].writeState === "pending")) {
                    objects[id].active = false; desired.push(objects[id])
                } else { objects[id].destroy(); delete objects[id] }
            }
        })
        controls = desired
        revision++
    }
    readonly property var arrangement: {
        const stamp = revision, config = JSON.parse(JSON.stringify(store.config)), availability = {}
        controls.forEach(c => { availability[c.controlId] = c.availability })
        const index = entries().map(e => {
            const meta = catalog.find(c => c.id === e.source)
            return Object.assign({}, meta, {id: e.id})
        })
        return Layout.arrange(config, index, availability, {rings: Schema.MAX_RINGS[config.size] || 3, toggles: controls.length}, 0, false, null)
    }
    readonly property var rings: arrangement.rings.map(e => byId(e.id)).filter(c => c !== null)
    readonly property var toggles: arrangement.toggles.map(e => byId(e.id)).filter(c => c !== null)
    function status() {
        return JSON.stringify({version: "0.1.0", schemaVersion: Schema.VERSION,
            controls: entries().map(e => {
                const c = byId(e.id), meta = catalog.find(m => m.id === e.source)
                return {id: e.id, kind: meta ? meta.kind : "readout", availability: c ? c.availability : "probing",
                    reason: c ? c.reason : "Not instantiated while hidden", value: c ? c.value : null}
            }), errors: store.errors || []})
    }
}
