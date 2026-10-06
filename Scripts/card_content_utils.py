#!/usr/bin/env python3
"""Kart metni normalizasyonu — token, süre ve biçim düzeltmeleri."""
from __future__ import annotations

import re
from typing import Optional, Tuple

DURATION_PATTERN = re.compile(
    r"(\d+)\s*(saniye|sn|dakika|dk)",
    re.IGNORECASE,
)
TRAILING_DURATION = re.compile(
    r"[,.]?\s*\d+\s*(?:saniye|sn|dakika|dk)"
    r"(?:\s+\d+\s*(?:saniye|sn))?"
    r"(?:\s+boyunca)?",
    re.IGNORECASE,
)
LEADING_ACTOR = re.compile(r"^\{sıradaki\}\s*,\s*", re.IGNORECASE)
LEGACY_LEADING_AO = re.compile(r"^\{AO\}\s*,\s*", re.IGNORECASE)
MULTISPACE = re.compile(r"  +")
SPACE_BEFORE_PUNCT = re.compile(r"\s+([,.])")
OLD_TOKENS = re.compile(r"\{HO\}|\{AO\}|\{ÜO\}|\{UO\}|(?<!\{)HO'|(?<!\{)AO(?![a-z])", re.I)


def duration_from_text(text: str) -> Optional[int]:
    total = 0
    for num, unit in DURATION_PATTERN.findall(text or ""):
        value = int(num)
        if unit.lower() in ("dakika", "dk"):
            total += value * 60
        else:
            total += value
    return total if total > 0 else None


def migrate_legacy_tokens(text: str) -> str:
    """Eski {HO}/{AO}/{ÜO} kodlarını okunabilir Türkçe token'lara çevirir."""
    if not text:
        return text
    result = text

    result = re.sub(r"\{AO\}\s+ve\s+\{HO\}", "{partner} ile", result, flags=re.IGNORECASE)
    result = re.sub(r"\{actor\}\s+ve\s+\{target\}", "{partner} ile", result, flags=re.IGNORECASE)

    partner_rules = (
        (r"\{HO\}'nun", "{partnerin}"),
        (r"\{HO\}'nın", "{partnerin}"),
        (r"\{HO\}'nün", "{partnerin}"),
        (r"\{HO\}'nin", "{partnerin}"),
        (r"HO'nun", "{partnerin}"),
        (r"HO'nın", "{partnerin}"),
        (r"HO'nün", "{partnerin}"),
        (r"HO'nin", "{partnerin}"),
        (r"\{HO\}'ya", "{partnere}"),
        (r"\{HO\}'ye", "{partnere}"),
        (r"HO'ya", "{partnere}"),
        (r"HO'ye", "{partnere}"),
        (r"\{HO\}'yu", "{partneri}"),
        (r"\{HO\}'yü", "{partneri}"),
        (r"\{HO\}'yi", "{partneri}"),
        (r"\{HO\}'yı", "{partneri}"),
        (r"HO'yu", "{partneri}"),
        (r"HO'yü", "{partneri}"),
        (r"HO'yi", "{partneri}"),
        (r"HO'yı", "{partneri}"),
        (r"\{HO\}'yla", "{partnerle}"),
        (r"\{HO\}'yle", "{partnerle}"),
        (r"HO'yla", "{partnerle}"),
        (r"HO'yle", "{partnerle}"),
        (r"\{target\}", "{partner}"),
        (r"\{HO\}", "{partner}"),
    )
    for pattern, replacement in partner_rules:
        result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)

    third_rules = (
        (r"\{ÜO\}'nun", "{diğer oyuncunun}"),
        (r"\{ÜO\}'nın", "{diğer oyuncunun}"),
        (r"\{UO\}'nun", "{diğer oyuncunun}"),
        (r"ÜO'nun", "{diğer oyuncunun}"),
        (r"ÜO'nın", "{diğer oyuncunun}"),
        (r"\{ÜO\}'ya", "{diğer oyuncuya}"),
        (r"\{UO\}'ya", "{diğer oyuncuya}"),
        (r"ÜO'ya", "{diğer oyuncuya}"),
        (r"\{ÜO\}'yu", "{diğer oyuncuyu}"),
        (r"\{UO\}'yu", "{diğer oyuncuyu}"),
        (r"ÜO'yu", "{diğer oyuncuyu}"),
        (r"\{ÜO\}'yla", "{diğer oyuncuyla}"),
        (r"\{UO\}'yla", "{diğer oyuncuyla}"),
        (r"ÜO'yla", "{diğer oyuncuyla}"),
        (r"\{ÜO\}", "{diğer oyuncu}"),
        (r"\{UO\}", "{diğer oyuncu}"),
    )
    for pattern, replacement in third_rules:
        result = re.sub(pattern, replacement, result, flags=re.IGNORECASE)

    result = re.sub(r"\{actor\}", "{sıradaki}", result, flags=re.IGNORECASE)
    result = re.sub(r"\{AO\}", "{sıradaki}", result, flags=re.IGNORECASE)

    return result


def normalize_role_tokens(text: str) -> str:
    return migrate_legacy_tokens(text)


def strip_duration_phrases(text: str) -> str:
    if not text:
        return text
    result = TRAILING_DURATION.sub("", text)
    result = re.sub(r"\s+boyunca\b", "", result, flags=re.IGNORECASE)
    return result


def cleanup_sentence(text: str) -> str:
    if not text:
        return text
    result = MULTISPACE.sub(" ", text)
    result = SPACE_BEFORE_PUNCT.sub(r"\1", result)
    result = result.strip(" ,.")
    result = re.sub(r"\s+ve\s*$", "", result, flags=re.IGNORECASE)
    result = re.sub(r"^\s*ve\s+", "", result, flags=re.IGNORECASE)
    return result.strip()


def normalize_field_text(text: str, *, strip_leading_actor: bool = False) -> str:
    if not text:
        return text
    result = normalize_role_tokens(text)
    result = strip_duration_phrases(result)
    if strip_leading_actor:
        result = LEADING_ACTOR.sub("", result)
        result = LEGACY_LEADING_AO.sub("", result)
    return cleanup_sentence(result)


def resolve_card_duration(card: dict) -> int:
    tier = card.get("contentTier", "beginning")
    deck = card.get("deckType", "")
    tier_default = {"beginning": 45, "medium": 75, "hot": 120}
    tier_max = {"beginning": 90, "medium": 120, "hot": 300}

    sources = []
    if deck == "neverHaveI" and card.get("onYesTask"):
        sources.append(card["onYesTask"])
    sources.append(card.get("text", ""))

    for src in sources:
        parsed = duration_from_text(src)
        if parsed:
            return min(parsed, tier_max.get(tier, 300))

    existing = card.get("durationSeconds")
    if isinstance(existing, int) and existing > 0:
        return existing

    if deck == "hardTruth":
        return 45
    if deck == "propTask":
        return 60
    return tier_default.get(tier, 60)


def normalize_card(card: dict) -> Tuple[dict, bool]:
    changed = False
    deck = card.get("deckType", "")
    is_task = card.get("type") in ("task", "roleDuo") or deck in (
        "hardAction",
        "fantasyRole",
        "propTask",
    )

    for field in ("text", "onYesTask"):
        raw = card.get(field)
        if not raw:
            continue
        normalized = normalize_field_text(
            raw,
            strip_leading_actor=is_task and field == "text",
        )
        if normalized != raw:
            card[field] = normalized
            changed = True

    new_duration = resolve_card_duration(card)
    if card.get("durationSeconds") != new_duration:
        card["durationSeconds"] = new_duration
        changed = True

    return card, changed


def has_legacy_tokens(text: str) -> bool:
    return bool(OLD_TOKENS.search(text or ""))
