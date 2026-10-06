#!/usr/bin/env python3
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple


REPO_ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = REPO_ROOT / "Scarlight/Resources/deck_packs.json"
TRANSCRIPTS_CANDIDATES = [
    Path.home() / ".cursor/projects/Users-efecanakbulut-Desktop-Projeler-Scarlight/agent-transcripts",
    Path.home() / ".cursor/projects/Users-efecanakbulut-Desktop-Projeler-asdasd/agent-transcripts",
]
TRANSCRIPTS_ROOT = next((p for p in TRANSCRIPTS_CANDIDATES if p.exists()), TRANSCRIPTS_CANDIDATES[0])

INTENSITY_BY_TIER = {"beginning": 3, "medium": 4, "hot": 5}
TASK_DURATION_RANGES = {"beginning": (30, 45), "medium": (60, 90), "hot": (90, 180)}
TASK_DEFAULT_BY_TIER = {"beginning": 45, "medium": 75, "hot": 120}


def _extract_full_prompt_text() -> str:
    """Find the long user prompt that contains all card lists."""
    for jsonl_path in TRANSCRIPTS_ROOT.rglob("*.jsonl"):
        try:
            lines = jsonl_path.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue
        for line in lines:
            try:
                obj = json.loads(line)
            except Exception:
                continue
            message = obj.get("message", {})
            content = message.get("content", [])
            if not isinstance(content, list):
                continue
            text_parts = []
            for part in content:
                if isinstance(part, dict) and part.get("type") == "text":
                    text_parts.append(part.get("text", ""))
            if not text_parts:
                continue
            merged = "\n".join(text_parts)
            if all(
                key in merged
                for key in ["BEN HİÇ", "HARD DOĞRULUK", "HARD AKSİYON", "FANTEZİ / ROL KARTLARI"]
            ):
                return merged
    raise RuntimeError("Card source text was not found in transcripts.")


def _section_between(text: str, start_marker: str, end_marker: Optional[str]) -> str:
    start_idx = text.find(start_marker)
    if start_idx < 0:
        return ""
    end_idx = len(text) if end_marker is None else text.find(end_marker, start_idx + len(start_marker))
    if end_idx < 0:
        end_idx = len(text)
    return text[start_idx:end_idx]


def _tier_chunk(section_text: str, tier: str) -> str:
    tier_markers = {
        "beginning": "BAŞLANGIÇ SEVİYESİ",
        "medium": "ORTA SEVİYE",
        "hot": "ATEŞLİ SEVİYE",
    }
    marker = tier_markers[tier]
    start = section_text.find(marker)
    if start < 0:
        return ""
    ends = []
    for other_tier, other_marker in tier_markers.items():
        if other_tier == tier:
            continue
        idx = section_text.find(other_marker, start + len(marker))
        if idx >= 0:
            ends.append(idx)
    end = min(ends) if ends else len(section_text)
    return section_text[start:end]


def _player_chunk(tier_chunk: str, players: int) -> str:
    player_marker = f"{players} Kişilik Oyun İçin"
    start = tier_chunk.find(player_marker)
    if start < 0:
        return ""
    next_marker = "3 Kişilik Oyun İçin" if players == 2 else None
    if next_marker:
        end = tier_chunk.find(next_marker, start + len(player_marker))
        if end >= 0:
            return tier_chunk[start:end]
    return tier_chunk[start:]


def _extract_numbered_items(block: str) -> List[str]:
    pattern = re.compile(r"(?ms)^\s*\d+\.\s+(.*?)(?=^\s*\d+\.\s+|\Z)")
    cards = []
    for match in pattern.finditer(block):
        item = re.sub(r"\s+", " ", match.group(1)).strip()
        item = item.rstrip(";")
        if item:
            cards.append(item)
    return cards


def _extract_yes_task(text: str) -> Tuple[str, Optional[str]]:
    m = re.search(r"\(Yaptıysan:\s*(.*?)\)\s*$", text, flags=re.IGNORECASE)
    if not m:
        return text.strip(), None
    task = m.group(1).strip()
    clean_text = text[: m.start()].strip()
    return clean_text, task


def _duration_from_text(text: str) -> Optional[int]:
    total = 0
    for num, unit in re.findall(r"(\d+)\s*(saniye|sn|dakika|dk)", text.lower()):
        value = int(num)
        if unit in ("dakika", "dk"):
            total += value * 60
        else:
            total += value
    return total if total > 0 else None


def _clamp_task_duration(tier: str, duration: int) -> int:
    lo, hi = TASK_DURATION_RANGES[tier]
    return max(lo, min(hi, duration))


def _build_card(
    *,
    card_id: str,
    deck_type: str,
    content_tier: str,
    min_players: int,
    max_players: int,
    phase: str,
    card_type: str,
    text: str,
    duration_seconds: int,
    intensity: int,
    on_yes_task: Optional[str] = None,
    required_prop_ids: Optional[List[str]] = None,
    prop_category: Optional[str] = None,
    title: Optional[str] = None,
) -> Dict:
    payload: Dict = {
        "id": card_id,
        "deckType": deck_type,
        "contentTier": content_tier,
        "minPlayers": min_players,
        "maxPlayers": max_players,
        "phase": phase,
        "type": card_type,
        "text": text,
        "durationSeconds": duration_seconds,
        "intensity": intensity,
    }
    if on_yes_task:
        payload["onYesTask"] = on_yes_task
    if required_prop_ids:
        payload["requiredPropIds"] = required_prop_ids
    if prop_category:
        payload["propCategory"] = prop_category
    if title:
        payload["title"] = title
    return payload


def _parse_main_decks(source_text: str) -> List[Dict]:
    cards: List[Dict] = []

    section_markers = {
        "neverHaveI": ("1. BEN HİÇ", "1. HARD DOĞRULUK"),
        "hardTruth": ("1. HARD DOĞRULUK", "1. HARD AKSİYON"),
        "hardAction": ("1. HARD AKSİYON", "1. FANTEZİ / ROL KARTLARI"),
        "fantasyRole": ("1. FANTEZİ / ROL KARTLARI", None),
    }
    section_texts = {
        key: _section_between(source_text, start, end)
        for key, (start, end) in section_markers.items()
    }

    # Requested sections: full 6 for NHI/HT/HA; FR only these four.
    wanted = []
    for tier in ("beginning", "medium", "hot"):
        for players in (2, 3):
            wanted.append(("neverHaveI", tier, players))
            wanted.append(("hardTruth", tier, players))
            wanted.append(("hardAction", tier, players))
    wanted.extend(
        [
            ("fantasyRole", "beginning", 2),
            ("fantasyRole", "beginning", 3),
            ("fantasyRole", "medium", 2),
            ("fantasyRole", "medium", 3),
        ]
    )

    prefix_map = {
        "neverHaveI": "nhi",
        "hardTruth": "ht",
        "hardAction": "ha",
        "fantasyRole": "fr",
    }
    tier_code = {"beginning": "b", "medium": "m", "hot": "h"}

    for deck_type, tier, players in wanted:
        section = section_texts.get(deck_type, "")
        tier_block = _tier_chunk(section, tier)
        player_block = _player_chunk(tier_block, players)
        items = _extract_numbered_items(player_block)

        # User asked to include numbered cards they provided (1-50 where present).
        if len(items) > 50:
            items = items[:50]

        for i, raw in enumerate(items, start=1):
            cid = f"{prefix_map[deck_type]}_{tier_code[tier]}{players}_{i:03d}"
            intensity = INTENSITY_BY_TIER[tier]

            if deck_type == "neverHaveI":
                clean_text, yes_task = _extract_yes_task(raw)
                task_duration = _duration_from_text(yes_task or "") or 45
                cards.append(
                    _build_card(
                        card_id=cid,
                        deck_type=deck_type,
                        content_tier=tier,
                        min_players=players,
                        max_players=players,
                        phase="boldQuestion",
                        card_type="question",
                        text=clean_text,
                        on_yes_task=yes_task,
                        duration_seconds=task_duration,
                        intensity=intensity,
                        title="Ben Hiç",
                    )
                )
            elif deck_type == "hardTruth":
                cards.append(
                    _build_card(
                        card_id=cid,
                        deck_type=deck_type,
                        content_tier=tier,
                        min_players=players,
                        max_players=players,
                        phase="boldQuestion",
                        card_type="question",
                        text=raw,
                        duration_seconds=45,
                        intensity=intensity,
                        title="Hard Doğruluk",
                    )
                )
            elif deck_type == "hardAction":
                parsed_duration = _duration_from_text(raw)
                if parsed_duration is None:
                    parsed_duration = TASK_DEFAULT_BY_TIER[tier]
                duration = _clamp_task_duration(tier, parsed_duration)
                cards.append(
                    _build_card(
                        card_id=cid,
                        deck_type=deck_type,
                        content_tier=tier,
                        min_players=players,
                        max_players=players,
                        phase="timedTask",
                        card_type="task",
                        text=raw,
                        duration_seconds=duration,
                        intensity=intensity,
                        title="Hard Aksiyon",
                    )
                )
            else:  # fantasyRole
                parsed_duration = _duration_from_text(raw)
                if parsed_duration is None:
                    parsed_duration = TASK_DEFAULT_BY_TIER[tier]
                duration = _clamp_task_duration(tier, parsed_duration)
                cards.append(
                    _build_card(
                        card_id=cid,
                        deck_type=deck_type,
                        content_tier=tier,
                        min_players=players,
                        max_players=players,
                        phase="roleDuo",
                        card_type="roleDuo",
                        text=raw,
                        duration_seconds=duration,
                        intensity=intensity,
                        title="Fantezi / Rol",
                    )
                )

    return cards


def _build_prop_cards() -> List[Dict]:
    cards: List[Dict] = []
    hot_count = 34
    ed_count = 18

    for i in range(hot_count):
        cards.append(
            _build_card(
                card_id=f"prop_hot_{i}",
                deck_type="propTask",
                content_tier="hot",
                min_players=2,
                max_players=3,
                phase="timedTask",
                card_type="task",
                text="{AO}, {HO} ile {item} kullanarak 60 saniye görev yapacak",
                duration_seconds=60,
                intensity=INTENSITY_BY_TIER["hot"],
                required_prop_ids=[f"hot_{i}"],
                prop_category="hotStimulating",
                title="Eşya Görevi",
            )
        )

    for i in range(ed_count):
        cards.append(
            _build_card(
                card_id=f"prop_ed_{i}",
                deck_type="propTask",
                content_tier="medium",
                min_players=2,
                max_players=3,
                phase="timedTask",
                card_type="task",
                text="{AO}, {HO} ile {item} kullanarak 60 saniye görev yapacak",
                duration_seconds=60,
                intensity=INTENSITY_BY_TIER["medium"],
                required_prop_ids=[f"ed_{i}"],
                prop_category="edibleReachable",
                title="Eşya Görevi",
            )
        )

    return cards


def main() -> None:
    source_text = _extract_full_prompt_text()
    main_cards = _parse_main_decks(source_text)
    prop_cards = _build_prop_cards()
    all_cards = main_cards + prop_cards

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text(json.dumps(all_cards, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Generated {len(all_cards)} cards")
    print(str(OUTPUT_PATH))


if __name__ == "__main__":
    main()
