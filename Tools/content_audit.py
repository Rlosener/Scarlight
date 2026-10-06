#!/usr/bin/env python3
import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Scarlight" / "Resources"

CARD_FILES = [
    "deck_packs.json",
    "prop_questions.json",
    "bar_social_packs.json",
]

LIGHTER_FILE = "lighter_questions.json"

DECK_TYPES = {
    "standard",
    "neverHaveI",
    "hardTruth",
    "hardAction",
    "fantasyRole",
    "propTask",
    "barNeverHaveI",
    "barTruth",
    "barDare",
}

CONTENT_TIERS = {"beginning", "medium", "hot"}
PHASES = {
    "boldQuestion",
    "surpriseQuestion",
    "timedTask",
    "wheel",
    "dice",
    "roleDuo",
    "finalFocus",
}
CARD_TYPES = {"question", "task", "surpriseQuestion", "wheel", "dice", "roleDuo", "penalty"}
PROP_CATEGORIES = {"touch", "sensory", "role", "tease", "comfort", "wild"}
PROP_CATEGORIES.update(
    {
        "hotStimulating",
        "Ateşli & Uyarıcı",
        "edibleReachable",
        "Yenilebilir ve Ulaşılabilir",
        "Yenilebilir",
        "psychoStimulant",
        "Uyarıcı",
    }
)
KNOWN_PLACEHOLDERS = {
    "actor",
    "target",
    "partner",
    "partnerin",
    "partnere",
    "partneri",
    "partnerle",
    "diğer oyuncu",
    "diğer oyuncunun",
    "diğer oyuncuya",
    "diğer oyuncuyu",
    "diğer oyuncuyla",
    "eşya",
    "item",
    "duration",
    "phase",
    "sıradaki",
    "AO",
    "HO",
    "ÜO",
    "UO",
}

DURATION_PATTERN = re.compile(
    r"\b\d+\s*(saniye|sn|dakika|dk)\b|\b(bir|iki|üç|dört|beş)\s+(saniye|dakika)\b",
    re.IGNORECASE,
)


def normalize_text(value):
    return re.sub(r"\s+", " ", value.casefold().strip())


def load_json(filename):
    path = RESOURCES / filename
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def add_issue(issues, severity, location, message):
    issues.append((severity, location, message))


def validate_card_file(filename, cards, issues):
    if not isinstance(cards, list):
        add_issue(issues, "ERROR", filename, "Kök JSON array olmalı.")
        return []

    required = {
        "id",
        "deckType",
        "contentTier",
        "minPlayers",
        "maxPlayers",
        "phase",
        "type",
        "text",
        "durationSeconds",
        "intensity",
    }
    valid_cards = []

    for index, card in enumerate(cards):
        location = f"{filename}[{index}]"
        if not isinstance(card, dict):
            add_issue(issues, "ERROR", location, "Kart object olmalı.")
            continue

        missing = sorted(required - set(card.keys()))
        if missing:
            add_issue(issues, "ERROR", location, f"Eksik alan: {', '.join(missing)}")
            continue

        card_id = card.get("id", "")
        if not isinstance(card_id, str) or not card_id.strip():
            add_issue(issues, "ERROR", location, "id boş olamaz.")

        text = card.get("text", "")
        if not isinstance(text, str) or not text.strip():
            add_issue(issues, "ERROR", location, "text boş olamaz.")
        elif len(text) > 180:
            add_issue(issues, "WARN", f"{filename}:{card_id}", f"Metin uzun ({len(text)} karakter).")

        on_yes = card.get("onYesTask")
        if on_yes is not None and (not isinstance(on_yes, str) or not on_yes.strip()):
            add_issue(issues, "WARN", f"{filename}:{card_id}", "onYesTask boş string.")

        deck_type = card.get("deckType")
        if deck_type not in DECK_TYPES:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", f"Geçersiz deckType: {deck_type}")

        content_tier = card.get("contentTier")
        if content_tier not in CONTENT_TIERS:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", f"Geçersiz contentTier: {content_tier}")

        phase = card.get("phase")
        if phase not in PHASES:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", f"Geçersiz phase: {phase}")

        card_type = card.get("type")
        if card_type not in CARD_TYPES:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", f"Geçersiz type: {card_type}")

        min_players = card.get("minPlayers")
        max_players = card.get("maxPlayers")
        if not isinstance(min_players, int) or not isinstance(max_players, int):
            add_issue(issues, "ERROR", f"{filename}:{card_id}", "minPlayers/maxPlayers integer olmalı.")
        elif min_players < 2 or max_players < min_players or max_players > 8:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", f"Oyuncu aralığı hatalı: {min_players}-{max_players}")

        duration = card.get("durationSeconds")
        if not isinstance(duration, int) or duration < 0:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", "durationSeconds negatif olmayan integer olmalı.")

        intensity = card.get("intensity")
        if not isinstance(intensity, int) or intensity < 1 or intensity > 5:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", "intensity 1-5 aralığında integer olmalı.")

        required_props = card.get("requiredPropIds")
        if required_props is not None:
            if not isinstance(required_props, list) or not all(isinstance(item, str) and item for item in required_props):
                add_issue(issues, "ERROR", f"{filename}:{card_id}", "requiredPropIds dolu string listesi olmalı.")
            if deck_type == "propTask" and not required_props:
                add_issue(issues, "ERROR", f"{filename}:{card_id}", "propTask kartında requiredPropIds boş olmamalı.")

        prop_category = card.get("propCategory")
        if prop_category is not None and prop_category not in PROP_CATEGORIES:
            add_issue(issues, "ERROR", f"{filename}:{card_id}", f"Geçersiz propCategory: {prop_category}")

        combined_text = " ".join(str(part) for part in [text, on_yes or ""] if part)
        for token in re.findall(r"\{([^{}]+)\}", combined_text):
            if token not in KNOWN_PLACEHOLDERS:
                add_issue(issues, "WARN", f"{filename}:{card_id}", f"Bilinmeyen placeholder: {{{token}}}")

        if card_type == "question" and DURATION_PATTERN.search(text):
            add_issue(issues, "WARN", f"{filename}:{card_id}", "Soru metninde süre ifadesi var.")

        if max_players == 2 and re.search(r"\{(ÜO|UO|diğer oyuncu)", combined_text, re.IGNORECASE):
            add_issue(issues, "WARN", f"{filename}:{card_id}", "2 kişilik kart üçüncü oyuncu placeholder'ı içeriyor.")

        valid_cards.append((filename, card))

    return valid_cards


def validate_lighter_questions(questions, issues):
    if not isinstance(questions, list):
        add_issue(issues, "ERROR", LIGHTER_FILE, "Kök JSON array olmalı.")
        return

    for index, question in enumerate(questions):
        location = f"{LIGHTER_FILE}[{index}]"
        if not isinstance(question, str) or not question.strip():
            add_issue(issues, "ERROR", location, "Çakmak sorusu boş string olamaz.")
        elif len(question) > 140:
            add_issue(issues, "WARN", location, f"Çakmak sorusu uzun ({len(question)} karakter).")

    duplicates = [text for text, count in Counter(normalize_text(q) for q in questions if isinstance(q, str)).items() if count > 1]
    for text in duplicates[:20]:
        add_issue(issues, "WARN", LIGHTER_FILE, f"Duplicate çakmak sorusu: {text}")


def parse_args():
    parser = argparse.ArgumentParser(description="Scarlight kart ve soru içeriklerini denetler.")
    parser.add_argument(
        "--strict-warnings",
        action="store_true",
        help="Warning varsa komutu başarısız sayar. Pre-release için kullanılır.",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    issues = []
    all_cards = []

    for filename in CARD_FILES:
        try:
            cards = load_json(filename)
        except Exception as exc:
            add_issue(issues, "ERROR", filename, f"JSON okunamadı: {exc}")
            continue
        all_cards.extend(validate_card_file(filename, cards, issues))

    try:
        validate_lighter_questions(load_json(LIGHTER_FILE), issues)
    except Exception as exc:
        add_issue(issues, "ERROR", LIGHTER_FILE, f"JSON okunamadı: {exc}")

    id_locations = defaultdict(list)
    text_locations = defaultdict(list)
    deck_counts = Counter()
    profile_counts = Counter()
    player_scope_counts = Counter()

    for filename, card in all_cards:
        card_id = card.get("id", "")
        id_locations[card_id].append(filename)
        text_locations[normalize_text(card.get("text", ""))].append(card_id)
        deck = card.get("deckType", "unknown")
        deck_counts[deck] += 1
        profile_counts["social" if deck.startswith("bar") else "intimate"] += 1
        player_scope_counts[f"{card.get('minPlayers')}-{card.get('maxPlayers')}"] += 1

    for card_id, locations in sorted(id_locations.items()):
        if card_id and len(locations) > 1:
            add_issue(issues, "ERROR", card_id, f"Duplicate id: {', '.join(locations)}")

    for text, card_ids in sorted(text_locations.items()):
        if text and len(card_ids) > 1:
            add_issue(issues, "WARN", ", ".join(card_ids[:5]), "Duplicate/çok benzer kart metni.")

    errors = [item for item in issues if item[0] == "ERROR"]
    warnings = [item for item in issues if item[0] == "WARN"]

    print("Scarlight content audit")
    print(f"- cards: {len(all_cards)}")
    print(f"- deck counts: {dict(sorted(deck_counts.items()))}")
    print(f"- profiles: {dict(sorted(profile_counts.items()))}")
    print(f"- player scopes: {dict(sorted(player_scope_counts.items()))}")
    print(f"- errors: {len(errors)}")
    print(f"- warnings: {len(warnings)}")

    for severity, location, message in issues[:80]:
        print(f"{severity}: {location}: {message}")

    if len(issues) > 80:
        print(f"... {len(issues) - 80} more issue(s)")

    if errors:
        return 1
    if args.strict_warnings and warnings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
