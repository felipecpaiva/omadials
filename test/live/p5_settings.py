"""Live check of the four settings fixed on 2026-11-17 that need a pointer: rest to open, tap zone, close when the
pointer leaves, wheel step. Mouse only, never keys, never clicks: the corner is opened by resting or over IPC, so a
window under the corner never gets a click. Puts back the exact config bytes, the volume and the pointer.
Run through test/live/run-p5.sh."""
import copy, json, math, os, subprocess, sys, time
sys.path.insert(0, os.path.expanduser("~/Work/omahop/tests"))
from uinput_kbd import Mouse

H = 1000                                  # logical height of the Z13 output (scale 1.6)
VOLUME_RING = (354 * math.sin(math.radians(50)), H - 354 * math.cos(math.radians(50)))  # volume ring at size M
AWAY = (900, 300)                         # far outside the corner, on the open click catcher
CONFIG = os.path.expanduser("~/.config/omadials/config.json")


def sh(*a): return subprocess.run(a, capture_output=True, text=True).stdout.strip()
def status(): return json.loads(sh("omarchy-shell", "omadials", "status"))
def is_open(): return status()["open"]
def volume(): return next(c["value"] for c in status()["controls"] if c["id"] == "volume")
def to(x, y): sh("hyprctl", "eval", f"hl.dispatch(hl.dsp.cursor.move({{ x = {round(x)}, y = {round(y)} }}))"); time.sleep(0.12)
def close(): sh("omarchy-shell", "omadials", "close"); time.sleep(0.6)


def write(cfg):
    tmp = CONFIG + ".p5tmp"
    with open(tmp, "w") as f: json.dump(cfg, f, indent=2)
    os.replace(tmp, CONFIG); time.sleep(0.8)   # the plugin watches the file


def with_(base, **paths):
    """Copy of base with dotted keys set, for example with_(c, **{"trigger.push": False})."""
    cfg = copy.deepcopy(base)
    for path, value in paths.items():
        node = cfg
        *parents, last = path.split(".")
        for p in parents: node = node.setdefault(p, {})
        node[last] = value
    return cfg


m = None   # the uinput mouse, set below
# A cursor warp sends no hover to the corner surface, so every arrival is real relative motion (uinput moves in
# physical px, scale 1.6; the screen edge stops the pointer, so overshooting lands exactly in the corner).
def slide(dx, dy): m.move(round(dx * 1.6), round(dy * 1.6), steps=25, pause=0.012); time.sleep(0.1)
def leave_corner(): slide(700, -500)


def rest_in_corner(wait=1.0):
    """Leave the corner first (resting there once suppresses the next push), then slide into the 2 px push spot."""
    to(*AWAY); time.sleep(0.3); to(60, H - 60); slide(-200, 200); time.sleep(wait)


results = {}
def check(name, ok, detail=""):
    results[name] = bool(ok); print(("PASS " if ok else "FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)


original = open(CONFIG, "rb").read()
base = json.loads(original)
base = with_(base, **{"trigger.push": True, "trigger.pushDelayMs": 150, "cornerIcon.mode": "always",
                      "behavior.closeOnPointerLeave": True, "behavior.idleTimeoutS": 10})
vol0 = sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@").split()[1]
cursor0 = json.loads(sh("hyprctl", "cursorpos", "-j") or '{"x":900,"y":300}')
try:
    with Mouse() as m:                     # moves and one wheel notch; this script never presses a button
        close()

        # 0. control: with the defaults, resting in the corner opens it (proves the rest method works here)
        write(base); rest_in_corner()
        check("control: rest opens with defaults", is_open()); close()

        # 1. rest to open off: resting does nothing
        write(with_(base, **{"trigger.push": False})); rest_in_corner()
        check("1 rest to open off: stays closed", not is_open()); close()

        # 2. tap zone: tab never shown and zone off means the corner sees no pointer at all
        write(with_(base, **{"cornerIcon.mode": "never", "trigger.tapZone": False})); rest_in_corner()
        check("2 tab never + zone off: stays closed", not is_open()); close()
        write(with_(base, **{"cornerIcon.mode": "never", "trigger.tapZone": True})); rest_in_corner()
        check("2 control: tab never + zone on: opens", is_open()); close()

        # 3. close when the pointer leaves
        write(base); rest_in_corner(); leave_corner(); time.sleep(1.3)
        check("3 control: leave on, moving away closes", not is_open()); close()
        write(with_(base, **{"behavior.closeOnPointerLeave": False, "behavior.idleTimeoutS": 5}))
        rest_in_corner(); opened = is_open(); leave_corner(); time.sleep(1.5)
        check("3 leave off: stays open after moving away", opened and is_open())
        time.sleep(5)
        check("3 leave off: closes after the 5 s close-after time", not is_open()); close()

        # 4. wheel step 10 on volume: one notch down takes 10 off
        write(with_(base, **{"options.volume.wheelStep": 10}))
        sh("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0.5"); time.sleep(0.5)
        sh("omarchy-shell", "omadials", "open"); time.sleep(0.8)
        to(VOLUME_RING[0] - 20, VOLUME_RING[1]); slide(20, 0); before = volume()
        m.wheel(-1)
        time.sleep(0.6); after = volume()
        check("4 wheel step 10: one notch is 10", before - after == 10, f"{before} -> {after}")
        close()
finally:
    with open(CONFIG, "wb") as f: f.write(original)
    sh("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol0)
    sh("omarchy-shell", "omadials", "close")
    to(cursor0["x"], cursor0["y"])
    same = open(CONFIG, "rb").read() == original
    print("restored config", "exact" if same else "DIFFERENT", "| volume", sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"))
print("RESULT", json.dumps(results))
