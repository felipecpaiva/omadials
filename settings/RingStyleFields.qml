pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
ColumnLayout {
    id: styles
    required property var theme
    required property var store
    required property string stylePath
    property bool common: false
    property bool readout: false
    property QtObject styleStore: QtObject {
        function value(path) {
            const result = styles.store.value(path);
            return result === undefined ? styles.store.config.ringStyle[path.split(".").pop()] : result;
        }
        function set(path, value) {
            if (!styles.common) return styles.store.set(path,value);
            const cfg = styles.store.config, old = cfg.ringStyle;
            let changes = [{path:path,value:value}];
            ["dials","readoutRings"].forEach(group => cfg[group].forEach((entry,index) => {
                const style = entry.style;
                if (style && ["track","knob","thickness"].every(key => group === "readoutRings" && key === "knob" || style[key] === old[key])) {
                    let next = Object.assign({},entry); delete next.style;
                    changes.push({path:group + "." + index,value:next});
                }
            }));
            return styles.store.setMany(changes);
        }
    }
    Repeater {
        model: [{key:"track",label:"Track",values:["solid","dashed","dotted","segmented"],pictures:["━━","╍╍","•••","━ ━"]},{key:"knob",label:"Knob",values:["round","bar","none"],pictures:["●","┃","○"]},{key:"thickness",label:"Thickness",values:["thin","normal","bold"],pictures:["─","━","▬"]}]
        PictureChoices {
            required property var modelData
            visible: !styles.readout || modelData.key !== "knob"
            theme: styles.theme; store: styles.styleStore; styleKey: modelData.key; path: styles.stylePath + "." + modelData.key
            label: modelData.label; choices: modelData.values; pictures: modelData.pictures
        }
    }
}
