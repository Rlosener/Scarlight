#!/bin/bash
# Simulator Documents'taki düzenlenmiş deste dosyalarını proje Resources'a kopyalar.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_RESOURCES="$(cd "$SCRIPT_DIR/.." && pwd)/Scarlight/Resources"
APP_DATA_NAME="Scarlight"

find_container() {
  find "$HOME/Library/Developer/CoreSimulator/Devices" \
    -path "*/data/Containers/Data/Application/*/Documents/deck_packs.json" 2>/dev/null \
    | while read -r deck_file; do
        app_root="$(dirname "$(dirname "$deck_file")")"
        bundle_id_file="$app_root/.com.apple.mobile_container_manager.metadata.plist"
        if [ -f "$bundle_id_file" ]; then
          echo "$deck_file"
          return 0
        fi
      done
}

DECK_FILE="$(find_container | head -1)"
if [ -z "$DECK_FILE" ]; then
  echo "Simulator'da düzenlenmiş deck_packs.json bulunamadı."
  echo "Önce uygulamada bir kart silin (Documents kopyası oluşur)."
  exit 1
fi

DOCS_DIR="$(dirname "$DECK_FILE")"
for file in deck_packs.json prop_questions.json; do
  if [ -f "$DOCS_DIR/$file" ]; then
    cp "$DOCS_DIR/$file" "$PROJECT_RESOURCES/$file"
    echo "Kopyalandı: $file"
  fi
done

echo "Tamam — proje kaynak dosyaları güncellendi."
