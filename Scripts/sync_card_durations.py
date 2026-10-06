#!/usr/bin/env python3
"""Metinde geçen süreleri durationSeconds alanına yazar (normalize_card_content kullanın)."""
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
JSON_PATH = REPO / "Scarlight/Resources/deck_packs.json"

sys.path.insert(0, str(REPO / "Scripts"))
from card_content_utils import normalize_card  # noqa: E402


def main() -> None:
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    changed = 0
    for i, card in enumerate(data):
        updated, did_change = normalize_card(card)
        data[i] = updated
        if did_change:
            changed += 1
    JSON_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Updated {changed}/{len(data)} cards → {JSON_PATH}")


if __name__ == "__main__":
    main()
