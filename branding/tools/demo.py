#!/usr/bin/env python3
"""Records the v0.7.0 feature GIFs from the REAL corner on a spare, empty workspace (never a virtual monitor).
Mouse only (uinput moves and clicks, never keys), plus omadials IPC commands and settings file edits. gifkit.py turns
each scene into a captioned GIF and MP4 in branding/demo/.
Scenes: open, dial, toggles, styles, battery, settings. The settings scene never shows the About page (it shows the
settings file path, which names the home folder).
Privacy and restore: Do Not Disturb is on while it runs; the settings file, volume, keep awake, Do Not Disturb, the
pointer and the workspace are put back. A demo window shows only this repository's README.
Needs grim, ffmpeg, kitty, bat, omadials-settings installed, and the omahop repo next to this one (its uinput helper).
Do not touch the keyboard or mouse while it runs (about 2 minutes).
Usage: python3 branding/tools/demo.py [scene ...]   (no argument: all scenes)"""
import json, math, os, shutil, subprocess, sys, tempfile, threading, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.expanduser("~/Work/omahop/tests"))
from uinput_kbd import Mouse
import gifkit

OUT = os.path.join(ROOT, "branding", "demo")
CFG = os.path.expanduser("~/.config/omadials/config.json")
SPARE = 8
H = 1000                                    # logical height of the Z13 screen (2560x1600 at scale 1.6)
CORNER = "0,380 1000x620"                    # the bottom-left corner and room for the captions above it
SETTINGS_AT = (200, 140)                     # where the settings window is placed, logical px
SETTINGS = f"{SETTINGS_AT[0]},{SETTINGS_AT[1]} 1200x760"
TOGGLE_R = 240
STEP = math.degrees(48 / TOGGLE_R)
VOLUME_R = 354                               # volume ring at Normal with the battery ring outside it
m = None


def sh(*a): return subprocess.run(a, capture_output=True, text=True).stdout.strip()
def ev(lua): subprocess.run(["hyprctl", "eval", lua], capture_output=True)
def ipc(*a): sh("qs", "ipc", "-p", "/usr/share/omarchy/shell", "call", "omadials", *a)
def status(): return json.loads(sh("qs", "ipc", "-p", "/usr/share/omarchy/shell", "call", "omadials", "status"))
def value(cid): return next(c["value"] for c in status()["controls"] if c["id"] == cid)
def to(x, y): ev(f"hl.dispatch(hl.dsp.cursor.move({{ x = {round(x)}, y = {round(y)} }}))"); time.sleep(0.12)
def at(r, a): return r * math.sin(math.radians(a)), H - r * math.cos(math.radians(a))
def toggle_angle(i): return 6 + STEP * (i + 0.5)
def slide(dx, dy, steps=30): m.move(round(dx * 1.6), round(dy * 1.6), steps=steps, pause=0.012); time.sleep(0.1)  # uinput is physical px
def click(): m.press(); time.sleep(0.05); m.release()


def write(cfg):
    tmp = CFG + ".demo"
    with open(tmp, "w") as f: json.dump(cfg, f, indent=2)
    os.replace(tmp, CFG); time.sleep(0.8)   # the plugin watches the file


def config(**extra):
    """The default settings, so the GIFs show what a new user sees, plus the scene's own keys."""
    cfg = {"version": 1}
    for path, v in extra.items():
        node = cfg; *parents, last = path.split(".")
        for p in parents: node = node.setdefault(p, {})
        node[last] = v
    return cfg


class Recorder:
    def __init__(self, region):
        self.region, self.frames, self.marks, self.stop = region, [], [], threading.Event()
        self.dir = tempfile.mkdtemp(prefix="omadials-demo-")

    def __enter__(self):
        self.t0 = time.time()
        def grab():
            n = 0
            while not self.stop.is_set():
                p = os.path.join(self.dir, f"f{n:05d}.jpg"); a = time.time() - self.t0
                subprocess.run(["grim", "-s", "1", "-g", self.region, "-t", "jpeg", "-q", "88", p], capture_output=True)
                self.frames.append((a, p)); n += 1
        self.th = threading.Thread(target=grab); self.th.start()
        return self

    def caption(self, text): self.marks.append((time.time() - self.t0, text))

    def finish(self, name, width=800):
        self.marks.append((time.time() - self.t0, ""))
        self.stop.set(); self.th.join()
        total = time.time() - self.t0
        gifkit.build(self.frames, total, self.marks, OUT, name, width=width, fps=15, fontsize=30)
        shutil.rmtree(self.dir, ignore_errors=True)
        print(f"wrote {name}.gif ({os.path.getsize(os.path.join(OUT, name + '.gif')) // 1024} KB, {total:.0f} s, {len(self.frames) / total:.0f} fps captured)", flush=True)

    def __exit__(self, *exc): self.stop.set()


def scene_open():
    write(config())
    to(700, 450)
    with Recorder(CORNER) as r:
        time.sleep(0.8); r.caption("Rest the pointer in the corner")
        to(60, H - 60); slide(-200, 200); time.sleep(1.8)
        r.caption("Move away and it closes"); slide(450, -350); time.sleep(1.6)
        r.caption("Or tap the corner"); to(6, H - 6); time.sleep(0.3); click(); time.sleep(1.6)
        r.caption("Click outside to close"); to(700, 450); time.sleep(0.4); click(); time.sleep(1.4)
        r.finish("open")


def drag(r0, a0, a1, step=1.5):
    """Press at angle a0 on radius r0 and slide to a1 with real relative motion (a warp sends no motion while pressed)."""
    to(*at(r0, a0)); m.press(); x, y = at(r0, a0); a = a0
    while (a1 - a) * (1 if a1 > a0 else -1) > 0:
        a += step if a1 > a0 else -step
        nx, ny = at(r0, a); m.move(round((nx - x) * 1.6), round((ny - y) * 1.6), steps=2); x, y = nx, ny


def scene_dial():
    write(config())
    sh("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "0.6")
    ipc("open"); time.sleep(0.8)
    with Recorder(CORNER) as r:
        time.sleep(0.6); r.caption("Drag a ring to set it")
        drag(VOLUME_R, 52, 28); time.sleep(0.3); m.release(); time.sleep(0.5)
        drag(VOLUME_R, 28, 62); m.release(); time.sleep(1.0)
        r.caption("Brightness, volume and mic, live"); time.sleep(1.4)
        ipc("close"); time.sleep(1.0)
        r.finish("dial")


def scene_toggles():
    write(config())
    ipc("open"); time.sleep(0.8)
    with Recorder(CORNER) as r:
        time.sleep(0.6); r.caption("Tap a toggle")
        to(*at(TOGGLE_R, toggle_angle(4))); time.sleep(0.3); click(); time.sleep(1.2)
        click(); time.sleep(1.0)
        r.caption("Slide the arc for more")
        drag(TOGGLE_R, toggle_angle(5), 16, step=1); time.sleep(0.3); m.release(); time.sleep(1.4)
        r.caption("Hold a toggle for its details")
        ipc("detail", "theme"); time.sleep(2.4)
        ipc("close"); time.sleep(1.2)
        r.finish("toggles")


STYLE_NAMES = {"morph": "Tab morph", "hybrid": "Hybrid", "lens": "Lens", "cascade": "Spring cascade", "minimal": "Minimal", "fan": "Fan"}


def scene_styles():
    with Recorder(CORNER) as r:
        for style, name in STYLE_NAMES.items():
            write(config(**{"animation.style": style}))
            r.caption(f"Open style: {name}"); time.sleep(0.4)
            ipc("open"); time.sleep(1.3); ipc("close"); time.sleep(1.0)
        r.finish("styles")


def scene_battery():
    write(config())
    with Recorder(CORNER) as r:
        time.sleep(0.4); r.caption("Battery ring in the closed tab"); time.sleep(1.8)
        r.caption("and in the open corner"); ipc("open"); time.sleep(2.2); ipc("close"); time.sleep(1.2)
        r.caption("Tab size: 60%"); write(config(**{"cornerIcon.scale": 0.6})); time.sleep(1.8)
        ipc("open"); time.sleep(1.6); ipc("close"); time.sleep(1.2)
        write(config()); time.sleep(0.6)
        r.finish("battery")


def scene_settings():
    write(config())
    before = {c["address"] for c in json.loads(sh("hyprctl", "clients", "-j"))}
    ev(f'hl.exec_cmd("[float; size 1200 760; move {SETTINGS_AT[0]} {SETTINGS_AT[1]}] omadials-settings")'); time.sleep(3.0)
    new = [c for c in json.loads(sh("hyprctl", "clients", "-j")) if c["address"] not in before]
    try:
        to(SETTINGS_AT[0] + 700, SETTINGS_AT[1] + 400)
        with Recorder(SETTINGS) as r:
            time.sleep(0.8); r.caption("A settings app with a live preview")
            for name, y in (("Rings", 146), ("Toggles", 198), ("Behavior", 250), ("Corner", 94)):
                time.sleep(1.6); r.caption(name); to(SETTINGS_AT[0] + 80, SETTINGS_AT[1] + y); time.sleep(0.3); click()
            time.sleep(2.0)
            r.finish("settings", width=900)
    finally:
        for c in new:
            ev(f'local w = hl.get_window("address:{c["address"]}"); if w then hl.dispatch(hl.dsp.window.close({{ window = w }})) end')
        time.sleep(1.0)


SCENES = {"open": scene_open, "dial": scene_dial, "toggles": scene_toggles, "styles": scene_styles, "battery": scene_battery, "settings": scene_settings}


def main():
    global m
    wanted = sys.argv[1:] or list(SCENES)
    if any(c["workspace"]["id"] == SPARE for c in json.loads(sh("hyprctl", "clients", "-j"))):
        raise SystemExit(f"spare workspace {SPARE} is not empty; not touching it")
    origin = json.loads(sh("hyprctl", "activeworkspace", "-j"))["id"]
    saved = open(CFG, "rb").read() if os.path.exists(CFG) else None
    vol0 = sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@").split()[1]
    awake0, dnd0 = value("keepawake"), sh("omarchy-shell", "notifications", "isDnd")
    cursor = json.loads(sh("hyprctl", "cursorpos", "-j") or '{"x":800,"y":500}')
    os.makedirs(OUT, exist_ok=True)
    print("Starting in 10 s. Hands off the keyboard, mouse and screen.", flush=True); time.sleep(10)
    try:
        if dnd0 != "on" and dnd0 != "true": sh("omarchy", "toggle", "notification", "silencing")
        ev(f'hl.dispatch(hl.dsp.focus({{ workspace = "{SPARE}" }}))'); time.sleep(0.8)
        readme = f"cd {ROOT} && bat --paging=never --style=plain --color=always --line-range=8:60 README.md; sleep 3600"
        ev(f'hl.exec_cmd("[float; size 1590 612; move 4 384] kitty --title README.md -e sh -c \'{readme}\'")'); time.sleep(2.5)
        with Mouse() as mouse:
            m = mouse; time.sleep(0.5)
            for name in wanted:
                print("scene", name, flush=True); SCENES[name]()
    finally:
        ipc("close")
        for c in json.loads(sh("hyprctl", "clients", "-j")):
            if c["workspace"]["id"] == SPARE:
                ev(f'local w = hl.get_window("address:{c["address"]}"); if w then hl.dispatch(hl.dsp.window.close({{ window = w }})) end')
        time.sleep(1.5)
        ev(f'hl.dispatch(hl.dsp.focus({{ workspace = "{origin}" }}))'); time.sleep(0.5)
        if saved is not None:
            with open(CFG, "wb") as f: f.write(saved)
        sh("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol0)
        if value("keepawake") != awake0: ipc("activate", "keepawake", "tap")
        if sh("omarchy-shell", "notifications", "isDnd") != dnd0: sh("omarchy", "toggle", "notification", "silencing")
        to(cursor["x"], cursor["y"])
        same = saved is None or open(CFG, "rb").read() == saved
        print("restored: config", "exact" if same else "DIFFERENT", "| volume", sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"),
              "| keep awake", value("keepawake"), "| dnd", sh("omarchy-shell", "notifications", "isDnd"), flush=True)


main()
