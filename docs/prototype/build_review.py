"""Build review.html (the published review page) from review.template.html plus the script in motion.html.

motion.html stays the only copy of the motion numbers. Run: python3 build_review.py
"""
import re
from pathlib import Path

here = Path(__file__).parent
motion = (here / "motion.html").read_text()
script = re.search(r"<script>\n(.*)</script>", motion, re.S).group(1)
# The simulated Omarchy theme belongs to the stage, not to the review page.
script = script.replace("document.documentElement.style.setProperty", "stage.style.setProperty")
script = script.replace("document.documentElement.style.colorScheme=light?'light':'dark';", "")
assert "documentElement" not in script, "motion.html touches the page root in a new way"
page = (here / "review.template.html").read_text().replace("/*MOTION_SCRIPT*/", script)
(here / "review.html").write_text(page)
print("wrote review.html")
