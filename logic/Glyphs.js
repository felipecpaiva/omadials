.pragma library
// Nerd Font (Material Design) glyphs for each control, as the stock Omarchy panels draw them. A name not in
// this table is treated as an icon theme name or a file by the view.
const GLYPHS = Object.freeze({
    brightness: "\u{F00E0}", volume: "\u{F057E}", mic: "\u{F036C}", wifi: "\u{F05A9}", bluetooth: "\u{F00AF}",
    nightlight: "\u{F0594}", dnd: "\u{F009B}", keepawake: "\u{F0176}", kbdlight: "\u{F030C}", airplane: "\u{F001D}",
    powerprofile: "\u{F04C5}", gameMode: "\u{F0297}", theme: "\u{F03D8}", media: "\u{F075A}",
    bluetoothBattery: "\u{F02CB}", wifiSignal: "\u{F0928}", laptopBattery: "\u{F0079}", penBattery: "\u{F03EA}",
    settings: "\u{F0493}"
});
function glyph(name) { return Object.prototype.hasOwnProperty.call(GLYPHS, name) ? GLYPHS[name] : ""; }
