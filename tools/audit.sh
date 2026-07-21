#!/bin/bash
#
# Audit built worksheets for the things that silently break them:
#   * a page whose content crosses the 11in print boundary (clipped when printed)
#   * an <image> with no <description>, so no alt text
#   * serif text in print preview (worksheets must be sans-serif)
#   * ink inside images below WCAG contrast -- catches Desmos' default
#     blue/green curve labels, which sit near 3.2-3.8:1 on white
#
# Usage:
#   tools/audit.sh                 # every target in project.ptx
#   tools/audit.sh session3        # one target
#
# Build first (tools/audit.sh reads output/<target>/); exits non-zero if any
# check fails, so it doubles as a pre-deploy gate.
#
set -u
cd "$(dirname "$0")/.."

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || { echo "Chrome not found at $CHROME" >&2; exit 2; }

if [ $# -gt 0 ]; then
  TARGETS="$*"
else
  TARGETS=$(python3 -c "
import xml.etree.ElementTree as ET
root = ET.parse('project.ptx').getroot()
print(' '.join(t.get('name') for t in root.iter('target') if t.get('name')))")
fi

PORT=8933
while lsof -i ":$PORT" >/dev/null 2>&1; do PORT=$((PORT + 1)); done
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' EXIT
sleep 2

FAILED=0
for T in $TARGETS; do
  WKS=$(ls "output/$T"/*wks.html 2>/dev/null | head -1)
  if [ -z "$WKS" ]; then
    echo "== $T: NO BUILD FOUND -- run: pretext build $T"
    FAILED=1
    continue
  fi
  REL="/${WKS}"
  ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$REL")
  DOM=$("$CHROME" --headless=new --disable-gpu --window-size=1200,1500 \
        --virtual-time-budget=40000 --dump-dom \
        "http://127.0.0.1:$PORT/tools/audit.html?t=$ENC" 2>/dev/null)

  echo "$DOM" | python3 -c "
import sys, re, html, json
raw = sys.stdin.read()
m = re.search(r'RESULT (\{.*?\})</pre>', raw, re.S)
target = '$T'
if not m:
    print(f'== {target}: audit harness produced no result (page failed to load?)')
    sys.exit(1)
d = json.loads(html.unescape(m.group(1)))
if 'error' in d:
    print(f'== {target}: {d[\"error\"]}')
    sys.exit(1)

bad = 0
print(f'== {target}')

over = [p for p in d['pages'] if p['over']]
if over:
    bad = 1
    for p in over:
        print(f'   FAIL  page {p[\"page\"]} overflows print boundary: {p[\"bottom\"]}px > {p[\"limit\"]}px')
else:
    worst = max(d['pages'], key=lambda p: p['bottom']) if d['pages'] else None
    n = len(d['pages'])
    if worst:
        print(f'   ok    {n} pages fit (fullest: page {worst[\"page\"]} at {worst[\"bottom\"]}/{worst[\"limit\"]}px)')

missing = [i for i in d['images'] if i['missing']]
if missing:
    bad = 1
    for i in missing:
        print(f'   FAIL  no alt text: {i[\"src\"]}  -- add a <description> to its <image>')
else:
    print(f'   ok    {len(d[\"images\"])} image(s), all with alt text')

serif = [t for t in d['text'] if t['serif']]
if serif:
    bad = 1
    for t in serif[:3]:
        print(f'   FAIL  serif font {t[\"font\"]!r} on {t[\"sample\"]!r}')
else:
    print('   ok    no serif text in print preview')

tfail = [t for t in d['text'] if t['fail']]
if tfail:
    bad = 1
    for t in tfail:
        print(f'   FAIL  text contrast {t[\"ratio\"]}:1 (needs {t[\"need\"]}) on {t[\"sample\"]!r}')
else:
    if d['text']:
        print(f'   ok    text contrast (lowest {min(t[\"ratio\"] for t in d[\"text\"])}:1)')

for k in d['ink']:
    if k['verdict'] == 'FAIL':
        bad = 1
        print(f'   FAIL  {k[\"src\"]}: {k[\"family\"]} ink rgb({k[\"rgb\"]}) at {k[\"ratio\"]}:1 -- below 3:1, too faint even for a bare curve')
    elif k['verdict'] == 'FAIL_LABEL':
        bad = 1
        print(f'   FAIL  {k[\"src\"]}: {k[\"family\"]} ink rgb({k[\"rgb\"]}) at {k[\"ratio\"]}:1 -- needs 4.5:1 for a curve label')
        print(f'         darken this ink in the PNG (see \"Fixing image contrast\" in CLAUDE.md).')
        print(f'         Only acceptable as-is if no text in the image uses this color.')
if d['ink'] and not any(k['verdict'] != 'OK' for k in d['ink']):
    print('   ok    image ink contrast')

sys.exit(1 if bad else 0)
" || FAILED=1
done

echo
if [ "$FAILED" -ne 0 ]; then
  echo "AUDIT FAILED"
  exit 1
fi
echo "audit passed"
