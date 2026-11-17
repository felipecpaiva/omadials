"""Live pointer check of the real plugin (P3 and P4), mouse only. Never sends keys: a key would reach the focused
window (spike S3). Restores the volume and do not disturb exactly as they were. Run through test/live/run-p4.sh."""
import json, math, os, subprocess, sys, time
sys.path.insert(0, os.path.expanduser("~/Work/omahop/tests"))
from uinput_kbd import Mouse

H = 1000                       # logical height of the Z13 output (scale 1.6)
R = 420                        # size M
RING = {"brightness": R - 22, "volume": R - 66, "mic": R - 110}
TOGGLE_R = 240
STEP = math.degrees(48 / TOGGLE_R)
OUT = os.environ.get("OUT", "/tmp")


def sh(*a): return subprocess.run(a, capture_output=True, text=True).stdout.strip()
def status(): return json.loads(sh("omarchy-shell", "omadials", "status"))
def value(cid): return next(c["value"] for c in status()["controls"] if c["id"] == cid)
def to(x, y): sh("hyprctl", "eval", f"hl.dispatch(hl.dsp.cursor.move({{ x = {round(x)}, y = {round(y)} }}))"); time.sleep(0.12)
def at(r, a): return r * math.sin(math.radians(a)), H - r * math.cos(math.radians(a))
def shot(name): sh("grim", "-g", "0,450 650x550", f"{OUT}/{name}.png")
def toggle_angle(i): return 6 + STEP * (i + 0.5)
def drag(m, r, a0, a1, step=2):
    """Press at angle a0 on radius r and slide to a1 with real relative motion (warps send no motion while pressed)."""
    to(*at(r, a0)); m.press(); x, y = at(r, a0)
    a = a0
    while (a1 - a) * (1 if a1 > a0 else -1) > 0:
        a += step if a1 > a0 else -step
        nx, ny = at(r, a); m.move(round((nx - x) * 1.6), round((ny - y) * 1.6), steps=2); x, y = nx, ny  # uinput moves in physical px


results = {}
def check(name, ok, detail=""):
    results[name] = bool(ok); print(("PASS " if ok else "FAIL ") + name + (f"  ({detail})" if detail else ""), flush=True)


vol0 = sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@").split()[1]
dnd0 = sh("omarchy-shell", "notifications", "isDnd")
try:
    with Mouse() as m:
        time.sleep(0.5)
        # 1. a tap in the 32 px corner opens the fan
        to(6, H - 6); m.press(); m.release(); time.sleep(0.6)
        check("tap opens", status()["open"]); shot("01-open")

        # 2. a tap on a ring without moving changes nothing (A-DIAL-1)
        before = value("volume"); to(*at(RING["volume"], 50)); m.press(); time.sleep(0.15); m.release(); time.sleep(0.4)
        check("tap on ring changes nothing", value("volume") == before, f"{before} -> {value('volume')}")

        # 3. dragging the volume ring sets the value under the finger
        drag(m, RING["volume"], 50, 30)
        time.sleep(0.25); shot("02-drag"); m.release(); time.sleep(0.5)
        got = value("volume"); want = round((30 - 3) / 84 * 100)
        check("drag sets volume", got < 110 and abs(got - want) <= 15, f"want ~{want}, got {got} (relative motion, pointer acceleration may shift it)")

        # 4. a tap on the do not disturb toggle (4th slot) switches it, a second tap switches it back
        to(*at(TOGGLE_R, toggle_angle(3))); m.press(); m.release(); time.sleep(1.2)
        d1 = sh("omarchy-shell", "notifications", "isDnd"); shot("03-dnd")
        to(*at(TOGGLE_R, toggle_angle(3))); m.press(); m.release(); time.sleep(1.2)
        d2 = sh("omarchy-shell", "notifications", "isDnd")
        check("toggle switches and switches back", d1 != dnd0 and d2 == dnd0, f"{dnd0} -> {d1} -> {d2}")

        # 5. press and slide along the arc scrolls the toggles (no toggle fires)
        dnd_before = sh("omarchy-shell", "notifications", "isDnd")
        drag(m, TOGGLE_R, toggle_angle(4), 20)
        time.sleep(0.25); shot("04-arc-scroll"); m.release(); time.sleep(0.5); shot("05-arc-snapped")
        check("arc slide fires no toggle", sh("omarchy-shell", "notifications", "isDnd") == dnd_before)

        # 6. an outside click closes, and the app below gets nothing
        to(900, 300); m.press(); m.release(); time.sleep(0.6)
        check("outside click closes", not status()["open"])

        # 7. reopen, hold the Wi-Fi toggle for 600 ms: its detail opens
        to(6, H - 6); m.press(); m.release(); time.sleep(0.6)
        to(*at(TOGGLE_R, toggle_angle(0))); m.press(); time.sleep(0.65); m.release(); time.sleep(0.6)
        shot("06-hold-detail"); check("still open after hold", status()["open"])
        to(900, 300); m.press(); m.release(); time.sleep(0.6)
finally:
    sh("wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol0)
    if sh("omarchy-shell", "notifications", "isDnd") != dnd0: sh("omarchy", "toggle", "notification", "silencing")
    sh("omarchy-shell", "omadials", "close")
    print("restored volume", sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"), "dnd", sh("omarchy-shell", "notifications", "isDnd"))
print("RESULT", json.dumps(results))
