# omadials file contract, schema v1

Schema v1 is frozen. This document supersedes the draft wording in architecture.md section 6. The executable validator is logic/ConfigSchema.js; controls/catalog.json owns extensible control options. Adding a catalog control does not change the version.

## Complete defaults and types

The following is the complete default file. Object keys are fixed except the catalog-owned maps controls and options. A literal defines its type: booleans are boolean, numbers are finite numbers, strings are strings, objects are objects, and arrays are arrays. No null scalar settings are accepted. Missing keys receive these defaults in memory; they are not silently written to disk.

```json
{
  "version": 1,
  "corner": "bottom-left",
  "size": "M",
  "outputs": {
    "mode": "all",
    "names": []
  },
  "trigger": {
    "tapZone": true,
    "push": true,
    "pushDelayMs": 150
  },
  "cornerIcon": {
    "mode": "always",
    "aboveWindows": true,
    "source": "default"
  },
  "controls": {
    "touchpad": {
      "shown": false,
      "icon": "default"
    },
    "touchscreen": {
      "shown": false,
      "icon": "default"
    },
    "chargeLimit": {
      "shown": false,
      "icon": "default"
    },
    "brightness": {
      "shown": true,
      "icon": "default"
    },
    "volume": {
      "shown": true,
      "icon": "default"
    },
    "mic": {
      "shown": true,
      "icon": "default"
    },
    "wifi": {
      "shown": true,
      "icon": "default"
    },
    "bluetooth": {
      "shown": true,
      "icon": "default"
    },
    "nightlight": {
      "shown": true,
      "icon": "default"
    },
    "dnd": {
      "shown": true,
      "icon": "default"
    },
    "keepawake": {
      "shown": true,
      "icon": "default"
    },
    "kbdlight": {
      "shown": true,
      "icon": "default"
    },
    "airplane": {
      "shown": true,
      "icon": "default"
    },
    "gameMode": {
      "shown": true,
      "icon": "default"
    },
    "theme": {
      "shown": true,
      "icon": "default"
    },
    "media": {
      "shown": true,
      "icon": "default"
    }
  },
  "behavior": {
    "idleTimeoutS": 10,
    "closeOnPointerLeave": true
  },
  "ringStyle": {
    "track": "solid",
    "knob": "round",
    "thickness": "normal"
  },
  "readoutRings": [],
  "dials": [
    {
      "id": "brightness",
      "order": 0,
      "style": {
        "track": "solid",
        "knob": "round",
        "thickness": "normal"
      }
    },
    {
      "id": "volume",
      "order": 1,
      "style": {
        "track": "solid",
        "knob": "round",
        "thickness": "normal"
      }
    },
    {
      "id": "mic",
      "order": 2,
      "style": {
        "track": "solid",
        "knob": "round",
        "thickness": "normal"
      }
    }
  ],
  "toggles": [
    {
      "id": "touchpad",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "touchscreen",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "wifi",
      "tapAction": "switchRadio",
      "holdAction": "quickDetail"
    },
    {
      "id": "bluetooth",
      "tapAction": "switchPower",
      "holdAction": "quickDetail"
    },
    {
      "id": "nightlight",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "dnd",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "keepawake",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "kbdlight",
      "tapAction": "nextStep",
      "holdAction": "quickDetail"
    },
    {
      "id": "airplane",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "gameMode",
      "tapAction": "switch",
      "holdAction": "quickDetail"
    },
    {
      "id": "theme",
      "tapAction": "quickDetail",
      "holdAction": "quickDetail"
    },
    {
      "id": "media",
      "tapAction": "quickDetail",
      "holdAction": "quickDetail"
    }
  ],
  "readout": {
    "battery": true,
    "powerProfile": true,
    "penBattery": true
  },
  "options": {
    "brightness": {
      "wheelStep": 5,
      "monitor": "auto"
    },
    "volume": {
      "wheelStep": 5,
      "maxPercent": 100
    },
    "mic": {
      "wheelStep": 5
    }
  },
  "tabStyle": "rings2knob",
  "dialInteraction": {
    "snap": true,
    "snapWindowPercent": 2,
    "fineEnabled": true,
    "fineDistancesPx": [
      22,
      66
    ],
    "fineGains": [
      0.25,
      0.1
    ]
  },
  "toggleScroll": "resetOnOpen",
  "animation": {
    "style": "morph",
    "speed": 1,
    "bounce": 0.06
  },
  "themePair": {
    "light": "",
    "dark": ""
  },
  "gameMode": {
    "animations": false,
    "blur": false,
    "shadows": false,
    "gapsIn": 0,
    "gapsOut": 0
  }
}
```

## Limits and enums

| Path | Accepted values and constraints |
|---|---|
| version | Integer 1. Missing is allowed only for an empty object. Older undocumented versions are read only. Newer versions are read only. |
| corner | top-left, top-right, bottom-left, bottom-right |
| size | S, M, L; combined shown dial/readout capacity 2, 3, 4 |
| outputs.mode | all, focused, named |
| outputs.names | Array of nonempty strings; named requires at least one |
| trigger.push | Boolean: open when the pointer rests in the corner (independent of cornerIcon.mode since 2026-11-17) |
| trigger.tapZone | Boolean: false means no corner zone while cornerIcon.mode is never (the corner then opens only by IPC or a shortcut) |
| trigger.pushDelayMs | Number 0 to 500 |
| behavior.idleTimeoutS | Number 0 to 120; 0 disables timeout |
| cornerIcon.mode | always, onApproach, never |
| cornerIcon.scale | Number 0.5 to 1, default 1: the closed tab size. The tab, its mini rings, knob and own icon get smaller together, and the open styles start from the smaller tab. The open corner keeps its size. |
| cornerIcon.source, controls.<id>.icon | default or a registered icon resource string |
| controls.<id> | Catalog id or configured readout id; object with shown boolean (new ids default false) and icon string (default default). Visibility lives here, never in list entries. |
| ringStyle.track, ring style.track | solid, dashed, dotted, segmented |
| ringStyle.knob, ring style.knob | round, bar, none; readouts force none and reject an explicit other value |
| ringStyle.thickness, ring style.thickness | thin, normal, bold |
| tabStyle | rings2knob, rings3 |
| toggleScroll | resetOnOpen |
| animation.style | morph (Tab morph, default), hybrid, lens, cascade (Spring cascade), minimal, fan; see experience.md "Open and close" |
| animation.speed | Number 0.5 to 2 (default 1); divides every open and close duration |
| animation.bounce | Number 0 to 0.35 (default 0.06); used by the spring styles (morph, hybrid, cascade) when opening, ignored by the others |
| dialInteraction.snapWindowPercent | Number 0 to 2 |
| dialInteraction.fineDistancesPx | Exactly two finite nonnegative numbers in increasing order |
| dialInteraction.fineGains | Exactly two finite numbers greater than 0 and at most 1 |
| themePair.light, themePair.dark | Deprecated 2026-11-17, kept so old files load. Empty string or an installed theme id |
| gameMode.gapsIn, gameMode.gapsOut | Finite nonnegative numbers, or null to leave the gaps alone. A bool set to true keeps the value from before game mode |

All other literal booleans retain boolean type. No additional constraints apply to the remaining literal fields. Unknown keys are reported, preserved in the source text and excluded from the runtime config. Validation errors are {path, code, message}; codes: parse_error, newer_version, wrong_type, out_of_range, unknown_value, unknown_control, duplicate_control, wrong_placement, over_capacity. Disk failures additionally report io_error.

## Placement lists

All three lists default as above. Each entry is an object. Ids are strings, unique across all lists, and must support the target placement in the catalog. Toggles use arc placement; dials and readoutRings use ring placement. List order determines toggle order. Ring order is the nonnegative safe integer order field (default entry index); duplicate ring orders are rejected across both ring lists. Hidden entries consume no capacity.

Dials accept only id, order and optional style. An omitted style inherits ringStyle; a supplied partial style fills from ringStyle. Readout rings additionally require source, one of bluetoothBattery, wifiSignal, laptopBattery, penBattery. Bluetooth requires deviceAddress (six colon-separated hexadecimal octets); pen requires devicePath starting /org/freedesktop/UPower/devices/; Wi-Fi interface defaults to auto and must be nonempty. Device fields are strings, cannot contain placeholders with <, and fields belonging to a different source are rejected. Readout ids are independent of source ids.

Toggles accept only id, tapAction and holdAction. Both actions are strings validated against the corresponding catalog action list, with schema fallback actions switch and quickDetail. Tap defaults to the first schema action; hold defaults to quickDetail. Special schema sets are wifi: switchRadio/quickDetail/fullWindow, bluetooth: switchPower/quickDetail/fullWindow, kbdlight: nextStep/quickDetail, theme: quickDetail (an old togglePair reads as quickDetail, no error), media: quickDetail. Catalog hold actions currently permit only quickDetail. Touchpad and touchscreen are listed but hidden by default; chargeLimit is hidden and can be added as a ring.

## Catalog option extensions

Options is a map from known catalog ids to objects. Omitted option maps retain the complete-file defaults above; individual backend options fall back to the catalog defaults below when absent. Unknown option fields are reported. Type follows the declared type; numeric min/max are inclusive. wheelStep must additionally be positive. maxPercent is exactly 100 or 150. Controls omitted below have empty option schemas.

```json
{
  "brightness": {
    "wheelStep": {
      "type": "number",
      "min": 1,
      "max": 25,
      "default": 5
    },
    "monitor": {
      "type": "string",
      "default": "auto"
    },
    "device": {
      "type": "string",
      "default": "amdgpu_bl1"
    }
  },
  "volume": {
    "wheelStep": {
      "type": "number",
      "min": 1,
      "max": 25,
      "default": 5
    },
    "maxPercent": {
      "type": "number",
      "enum": [
        100,
        150
      ],
      "default": 100
    }
  },
  "mic": {
    "wheelStep": {
      "type": "number",
      "min": 1,
      "max": 25,
      "default": 5
    }
  },
  "kbdlight": {
    "device": {
      "type": "string",
      "default": "asus::kbd_backlight"
    },
    "maxLevel": {
      "type": "number",
      "min": 1,
      "max": 10,
      "default": 3
    }
  }
}
```

## Migration and write ordering

logic/ConfigMigrate.js owns ordered pure steps keyed by source version: N maps to N+1. Each step must preserve unrelated and unknown fields, return a fresh object, perform no IO and advance exactly one version. Each future step ships input/expected fixture pairs under test/fixtures/config/. v1 has no predecessor contract and no migration steps; never invent a v0 conversion.

ConfigStore migrates in memory on read. It does not write merely because a file was loaded. On the next user write it patches the migrated object, validates it, then uses FileView to save the exact original text to the sibling config.v<N>.bak before replacing config.json. A preexisting backup is retained. Inspection or backup failure aborts the config write. Both writes use atomicWrites; no Process is used. A newer version or invalid JSON is read only. Reset is the explicit recovery action. Normal edits reread disk before patching, preserve unknown keys and serialize writes. Undo is available for 10 seconds and writes the previous text; external changes cancel undo.

## Disk IO inventory

| Path | Read/write behavior |
|---|---|
| ~/.config/omadials/config.json | Watched and read by ConfigStore; atomic writes on user edits, reset and undo. Missing file uses defaults in memory. Parent directory must exist. |
| ~/.config/omadials/config.v<N>.bak | Exact original config text, migration-only backup before the first migrating write; existing backup retained. |
| controls/catalog.json | Read-only packaged catalog. |
| $XDG_STATE_HOME/omadials/airplane-restore.json (fallback ~/.local/state) | Atomic prior radio soft-block journal before airplane enable; read on restart, deleted after verified restore. |
| $XDG_STATE_HOME/omadials/game-restore.json (fallback ~/.local/state) | Runtime game settings restore journal; retained on failed recovery. |
| ~/.local/state/omarchy/toggles/hypr/{touchpad,touchscreen}-disabled-name | Read/watch only by this plugin; existence means disabled. Omarchy helper owns writes. Missing file means enabled; other IO errors mean unknown. |
| /sys/class/power_supply/BAT0/charge_control_end_threshold | Read only, percent 20 to 100. Writes go exclusively through asusctl battery limit N; without asusctl the control stays read only. |
| /sys/class/leds | Read to detect the first keyboard backlight. brightnessctl reads native levels and performs absolute writes. |
| ~/.local/state/omarchy/notifications/quiet.json and indicators/stay-awake | Read/watch triggers for DND and keep awake; stock commands own writes. |

Theme discovery and current theme files are read only; stock theme commands own changes. No shell.json or Hyprland configuration is written. No commands or passwords are accepted from config. Device writes use fixed argv through core/CommandRunner.qml.
