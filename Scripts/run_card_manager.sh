#!/bin/bash
# Scarlight Soru Yönetimi — tarayıcıda açılır
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/Tools/CardManager"
echo ""
echo "  Soru Yönetimi açılıyor…"
echo "  Kapatmak için Ctrl+C"
echo ""
exec python3 app.py
