.pragma library
// Words people read for config values. Unknown values fall back to a spaced, capitalised form of the key.
const LABELS = Object.freeze({
    'bottom-left': 'Bottom left', 'bottom-right': 'Bottom right', 'top-left': 'Top left', 'top-right': 'Top right',
    S: 'Compact', M: 'Normal', L: 'Large',
    rings2knob: '2 rings and a knob', rings3: '3 rings', rings3knob: '3 rings and a knob',
    always: 'Always', onApproach: 'On approach', never: 'Never',
    all: 'All screens', focused: 'Focused screen', named: 'Named screens',
    solid: 'Solid', dashed: 'Dashed', dotted: 'Dotted', segmented: 'Segmented',
    round: 'Round', bar: 'Bar', none: 'None', thin: 'Thin', normal: 'Normal', bold: 'Bold',
    switchRadio: 'Switch radio', switchPower: 'Switch power', 'switch': 'Switch', quickDetail: 'Quick detail',
    fullWindow: 'Full window', nextStep: 'Next level', 'default': 'Default', '': 'None',
    morph: 'Tab morph', hybrid: 'Hybrid', lens: 'Lens', cascade: 'Spring cascade', minimal: 'Minimal', fan: 'Fan'
});
// One line on what each animation style does, for the Animation setting.
const DESCRIPTIONS = Object.freeze({
    morph: 'The tab grows into the corner and its small rings fly out to become the full rings.',
    hybrid: 'One spring grows the corner out of the tab and shows the rings as it passes them.',
    lens: 'The corner is revealed from the tab on a fixed curve: quick start, soft landing, no bounce.',
    cascade: 'The corner springs out of the tab, then the rings arrive one by one.',
    minimal: 'A short grow and fade out of the tab. The least motion.',
    fan: 'The rings unfold from the screen edge like a fan as the corner grows.'
});
function description(value) { return Object.prototype.hasOwnProperty.call(DESCRIPTIONS, String(value)) ? DESCRIPTIONS[String(value)] : ''; }
function label(value) {
    const key = String(value);
    if (Object.prototype.hasOwnProperty.call(LABELS, key)) return LABELS[key];
    const spaced = key.replace(/([a-z])([A-Z])/g, '$1 $2').replace(/[-_]/g, ' ');
    return spaced.charAt(0).toUpperCase() + spaced.slice(1).toLowerCase();
}
function options(values) { return (values || []).map(function(v) { return {value: String(v), label: label(v)}; }); }
// One status row in words, for the settings status lists (app and panel).
function statusText(entry) {
    if (!entry) return 'Unknown';
    if (entry.hidden) return 'Hidden';
    switch (entry.availability) {
    case 'available': return 'Working';
    case 'probing': return 'Checked when the corner opens';
    case 'unavailable': return 'Not on this machine' + (entry.reason ? ' (' + entry.reason + ')' : '');
    case 'error': return 'Problem' + (entry.reason ? ': ' + entry.reason : '');
    default: return 'Unknown';
    }
}
