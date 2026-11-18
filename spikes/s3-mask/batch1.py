import json, os, subprocess, sys, time
sys.path.insert(0, os.path.expanduser("~/Work/omahop/tests"))  # uinput helper from the omahop repo
from uinput_kbd import Mouse
SP = os.path.dirname(os.path.abspath(__file__))
def sh(*a): return subprocess.run(a, capture_output=True, text=True).stdout.strip()
def st(): return json.loads(sh("qs", "-p", SP, "ipc", "call", "s3", "state"))
def active(): return json.loads(sh("hyprctl", "activewindow", "-j") or "{}").get("address", "")
def to(x, y): sh("hyprctl", "eval", f"hl.dispatch(hl.dsp.cursor.move({{ x = {x}, y = {y} }}))"); time.sleep(0.4)
def click(m): m.press(); m.release(); time.sleep(0.4)
res = {}
w0 = active()
with Mouse() as m:  # no keyboard: a key would go to the focused window (it stopped earlier runs)
    time.sleep(0.5)
    to(6, 994); click(m); res["tap_opens"] = st()["open"]; print("step 1 tap opens:", res["tap_opens"])
    to(6, 994); click(m); res["second_tap_closes"] = not st()["open"]; print("step 2 second tap closes:", res["second_tap_closes"])
    to(6, 994); click(m); before = st()["open"]
    to(800, 300); click(m); s = st(); res["outside_closes"] = before and not s["open"]; print("step 3 outside click closes:", res["outside_closes"])
    res["window_keeps_focus"] = active() == w0; print("step 4 your window keeps focus:", res["window_keeps_focus"])
    to(700, 400); click(m); res["closed_click_passes"] = st()["open"] is False and st()["outside"] == s["outside"]; print("step 5 closed click passes through:", res["closed_click_passes"])
print("RESULT", json.dumps(res))
