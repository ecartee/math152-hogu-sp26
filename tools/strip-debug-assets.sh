#!/bin/bash
#
# Drop debugging artifacts from built targets before they are deployed.
#
# Every PreTeXt HTML target carries a ~32MB `_static/` bundle, and because each
# session deploys to its own directory that bundle is duplicated per session.
# Two kinds of file in it are dead weight for a published worksheet site:
#
#   *.map   ~18MB/target. JavaScript source maps for Runestone's bundles.
#           Browsers fetch them only when devtools is open, and nobody debugs
#           Runestone from here. Absent maps are silently ignored.
#   *.gz    ~7MB/target. Pre-compressed copies served only by web servers
#           configured for them (nginx gzip_static and friends). GitHub Pages
#           compresses on the fly and never reads these.
#
# Together that is ~76% of the deployed site. This does NOT touch the actual
# runtime (JS, CSS, fonts, sql-wasm.wasm), so interactive features keep working
# if a worksheet ever uses them.
#
# Run after building and before `pretext deploy`; deploy.sh does this. A later
# `pretext build` regenerates the files, so this is not destructive.
#
set -eu
cd "$(dirname "$0")/.."

[ -d output ] || { echo "strip-debug-assets: no output/ -- build first" >&2; exit 1; }

before=$(du -sk output 2>/dev/null | cut -f1)
maps=$(find output -path "*/_static/*" -name "*.map" | wc -l | tr -d ' ')
gzs=$(find output -path "*/_static/*" -name "*.gz" | wc -l | tr -d ' ')

find output -path "*/_static/*" -name "*.map" -delete
find output -path "*/_static/*" -name "*.gz" -delete

after=$(du -sk output 2>/dev/null | cut -f1)
echo "stripped $maps source maps and $gzs pre-gzipped files: $((before / 1024))MB -> $((after / 1024))MB"
