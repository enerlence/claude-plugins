#!/usr/bin/env bash
# Monta el ZIP para platform.openai.com/plugins (formato Agent Plugins 1.0.0).
#   DEMO_VIDEO_URL=https://… ./openai/suntropy-connect-monitoring/build.sh
# La skill y el logo se copian del plugin de Claude, para que no haya dos fuentes.
set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
ORIGEN="$RAIZ/plugins/suntropy-connect-monitoring"
OUT="$AQUI/dist"; TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/assets" "$TMP/skills" "$OUT"
cp "$AQUI/mcp.json" "$TMP/"
cp "$ORIGEN/.claude-plugin/icon.png" "$TMP/assets/logo.png"
cp -R "$ORIGEN/skills/suntropy-connect-monitoring" "$TMP/skills/"
# OpenAI no deja que una skill mande al modelo a otros conectores: fuera la línea de PVsyst/PV*SOL.
python3 - "$TMP/skills/suntropy-connect-monitoring/diagnosis.md" <<'PY'
import sys; p=sys.argv[1]; s=open(p,encoding='utf-8').read().split('\n')
s=[l for l in s if 'Suntropy Connect tools are available' not in l]
open(p,'w',encoding='utf-8').write('\n'.join(s))
PY
python3 - "$AQUI/plugin.json" "$TMP/plugin.json" <<'PY'
import json, os, sys
d=json.load(open(sys.argv[1])); v=os.environ.get('DEMO_VIDEO_URL','').strip()
if v: d['extensions']['com.openai']['review']['demo_recording_url']=v
else: print('⚠️  Sin DEMO_VIDEO_URL: la revisión lo exige; súbelo después o vuelve a montar el ZIP.')
json.dump(d, open(sys.argv[2],'w'), indent=2, ensure_ascii=False)
PY
VERSION=$(python3 -c "import json;print(json.load(open('$AQUI/plugin.json'))['version'])")
ZIP="$OUT/suntropy-connect-monitoring-$VERSION.zip"
rm -f "$ZIP"; (cd "$TMP" && zip -qr -X "$ZIP" .)
echo "$ZIP"; unzip -Z1 "$ZIP"
