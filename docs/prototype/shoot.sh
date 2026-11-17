#!/usr/bin/env bash
# Screenshot review.html in all 4 corners with long text, for layout checks.
# Usage: ./shoot.sh OUTDIR   (needs chromium; run build_review.py first)
set -euo pipefail
out=${1:?usage: shoot.sh OUTDIR}; mkdir -p "$out"
here=$(cd "$(dirname "$0")" && pwd)
long="Wi-Fi: on, Workshop very long wireless network 5G, signal 72%, connected for 2 h"
for c in bl br tl tr; do
  hook="setTimeout(()=>{\$('reduced').checked=true;reduced(true);\$('corner').value='$c';\$('corner').onchange();openFan();say(\"$long\");render();},300);"
  sed "0,/<\/script>/! s#</script>#;$hook</script>#" "$here/review.html" > "$out/t_$c.html"
  chromium --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=1200,1250 \
    --virtual-time-budget=3000 --screenshot="$out/$c.png" "file://$out/t_$c.html" >/dev/null 2>&1
done
echo "screenshots in $out: bl.png br.png tl.png tr.png"
