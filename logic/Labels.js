.pragma library
// Words people read for config values. Unknown values fall back to a spaced, capitalised form of the key.
const LABELS = Object.freeze({
    'bottom-left': 'Bottom left', 'bottom-right': 'Bottom right', 'top-left': 'Top left', 'top-right': 'Top right',
    S: 'Compact', M: 'Normal', L: 'Large',
    rings2knob: '2 rings and a knob', rings3: '3 rings',
    always: 'Always', onApproach: 'On approach', never: 'Never',
    all: 'All screens', focused: 'Focused screen', named: 'Named screens',
    solid: 'Solid', dashed: 'Dashed', dotted: 'Dotted', segmented: 'Segmented',
    round: 'Round', bar: 'Bar', none: 'None', thin: 'Thin', normal: 'Normal', bold: 'Bold',
    switchRadio: 'Switch radio', switchPower: 'Switch power', 'switch': 'Switch', quickDetail: 'Quick detail',
    fullWindow: 'Full window', nextStep: 'Next level', 'default': 'Default', '': 'None'
});
function label(value) {
    const key = String(value);
    if (Object.prototype.hasOwnProperty.call(LABELS, key)) return LABELS[key];
    const spaced = key.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/[-_]/g, ' ');
    return spaced.charAt(0).toUpperCase() + spaced.slice(1).toLowerCase();
}
function options(values) { return (values || []).map(function(v) { return {value: String(v), label: label(v)}; }); }
