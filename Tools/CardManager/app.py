#!/usr/bin/env python3
"""Scarlight Kart Yöneticisi — yerel web arayüzü (stdlib, Flask gerekmez)."""
from __future__ import annotations

import json
import re
import sys
import uuid
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Timer
from urllib.parse import parse_qs, unquote, urlparse

REPO = Path(__file__).resolve().parents[2]
RESOURCES = REPO / "Scarlight/Resources"
STATIC = Path(__file__).resolve().parent / "static"
SCRIPTS = REPO / "Scripts"
sys.path.insert(0, str(SCRIPTS))

from card_content_utils import normalize_card  # noqa: E402

DECK_FILE = "deck_packs.json"
PROP_FILE = "prop_questions.json"
PORT = 8765


def _path_for(filename: str) -> Path:
    return RESOURCES / filename


def _load_file(filename: str) -> list[dict]:
    path = _path_for(filename)
    if not path.exists():
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def _save_file(filename: str, data: list[dict]) -> None:
    path = _path_for(filename)
    path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _file_for_id(card_id: str) -> str:
    return PROP_FILE if card_id.startswith("prop_") else DECK_FILE


def _all_cards() -> list[dict]:
    cards: list[dict] = []
    for filename in (DECK_FILE, PROP_FILE):
        for card in _load_file(filename):
            item = dict(card)
            item["_file"] = filename
            cards.append(item)
    return cards


def _find_index(filename: str, card_id: str) -> int | None:
    for i, card in enumerate(_load_file(filename)):
        if card.get("id") == card_id:
            return i
    return None


def _card_player_scope(card: dict) -> str:
    min_p = int(card.get("minPlayers") or 2)
    max_p = int(card.get("maxPlayers") or 2)
    if min_p >= 3 and max_p <= 3:
        return "3"
    if max_p <= 2:
        return "2"
    return "23"


def _matches_player_filter(card: dict, players: str) -> bool:
    if not players:
        return True
    return _card_player_scope(card) == players


def _preview_text(text: str) -> str:
    if not text:
        return ""
    result = text
    for src, dst in (
        ("{partnerin}", "partnerin"),
        ("{partnere}", "partnere"),
        ("{partneri}", "partneri"),
        ("{partnerle}", "partnerle"),
        ("{partner}", "partner"),
        ("{diğer oyuncunun}", "diğer oyuncunun"),
        ("{diğer oyuncuya}", "diğer oyuncuya"),
        ("{diğer oyuncuyu}", "diğer oyuncuyu"),
        ("{diğer oyuncuyla}", "diğer oyuncuyla"),
        ("{diğer oyuncu}", "diğer oyuncu"),
        ("{eşya}", "eşya"),
        # Eski kodlar (geriye dönük önizleme)
        ("{HO}'nun", "partnerin"),
        ("{HO}'nın", "partnerin"),
        ("{HO}'ya", "partnere"),
        ("{HO}'yu", "partneri"),
        ("{HO}'yla", "partnerle"),
        ("{HO}", "partner"),
        ("{ÜO}", "diğer oyuncu"),
        ("{UO}", "diğer oyuncu"),
    ):
        result = result.replace(src, dst)
    result = re.sub(r"^\{sıradaki\}\s*,\s*", "", result, flags=re.I)
    result = re.sub(r"^\{AO\}\s*,\s*", "", result, flags=re.I)
    result = re.sub(r"\{[^{}]+\}", "", result)
    return result.strip()


def _payload_to_entry(payload: dict, card_id: str) -> dict:
    return {
        "id": card_id,
        "deckType": payload.get("deckType", "neverHaveI"),
        "contentTier": payload.get("contentTier", "beginning"),
        "minPlayers": int(payload.get("minPlayers", 2)),
        "maxPlayers": int(payload.get("maxPlayers", 2)),
        "phase": payload.get("phase", "boldQuestion"),
        "type": payload.get("type", "question"),
        "text": (payload.get("text") or "").strip(),
        "onYesTask": (payload.get("onYesTask") or "").strip() or None,
        "durationSeconds": int(payload.get("durationSeconds", 45)),
        "intensity": int(payload.get("intensity", 3)),
        "requiredPropIds": payload.get("requiredPropIds") or None,
        "propCategory": payload.get("propCategory") or None,
        "title": (payload.get("title") or "").strip() or None,
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args) -> None:
        print(fmt % args)

    def _json(self, data, status: int = 200) -> None:
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        if length <= 0:
            return {}
        return json.loads(self.rfile.read(length).decode("utf-8"))

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/index.html":
            return self._serve_static("index.html", "text/html; charset=utf-8")

        if path.startswith("/api/cards/"):
            card_id = unquote(path.split("/api/cards/", 1)[1])
            for card in _all_cards():
                if card.get("id") == card_id:
                    out = dict(card)
                    out["previewText"] = _preview_text(card.get("text", ""))
                    out["previewYesTask"] = _preview_text(card.get("onYesTask") or "")
                    return self._json(out)
            return self._json({"error": "Kart bulunamadı"}, 404)

        if path == "/api/cards":
            qs = parse_qs(parsed.query)
            q = (qs.get("q", [""])[0] or "").strip().lower()
            deck = qs.get("deckType", [""])[0]
            tier = qs.get("tier", [""])[0]
            source = qs.get("source", [""])[0]
            players = qs.get("players", [""])[0]
            cards = _all_cards()
            if source in (DECK_FILE, PROP_FILE):
                cards = [c for c in cards if c["_file"] == source]
            if deck:
                cards = [c for c in cards if c.get("deckType") == deck]
            if tier:
                cards = [c for c in cards if c.get("contentTier") == tier]
            if players in ("2", "3", "23"):
                cards = [c for c in cards if _matches_player_filter(c, players)]
            if q:
                cards = [
                    c
                    for c in cards
                    if q in (c.get("id") or "").lower()
                    or q in (c.get("text") or "").lower()
                    or q in (c.get("onYesTask") or "").lower()
                    or q in (c.get("title") or "").lower()
                ]
            return self._json(cards)

        if path == "/api/stats":
            cards = _all_cards()
            by_deck: dict[str, int] = {}
            by_file = {DECK_FILE: 0, PROP_FILE: 0}
            by_players = {"2": 0, "3": 0, "23": 0}
            for c in cards:
                by_deck[c.get("deckType", "?")] = by_deck.get(c.get("deckType", "?"), 0) + 1
                by_file[c["_file"]] = by_file.get(c["_file"], 0) + 1
                by_players[_card_player_scope(c)] = by_players.get(_card_player_scope(c), 0) + 1
            return self._json({
                "total": len(cards),
                "byDeck": by_deck,
                "byFile": by_file,
                "byPlayers": by_players,
            })

        if path == "/api/meta":
            return self._json(
                {
                    "deckTypes": [
                        "neverHaveI",
                        "hardTruth",
                        "hardAction",
                        "fantasyRole",
                        "propTask",
                    ],
                    "tiers": ["beginning", "medium", "hot"],
                    "phases": [
                        "boldQuestion",
                        "surpriseQuestion",
                        "timedTask",
                        "roleDuo",
                        "wheel",
                        "dice",
                        "finalFocus",
                    ],
                    "types": ["question", "task", "roleDuo", "wheel", "dice"],
                    "files": [DECK_FILE, PROP_FILE],
                    "resourcesPath": str(RESOURCES),
                }
            )

        return self._json({"error": "Not found"}, 404)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/cards":
            payload = self._read_json()
            filename = payload.get("_file") or DECK_FILE
            if filename not in (DECK_FILE, PROP_FILE):
                return self._json({"error": "Geçersiz dosya"}, 400)
            card_id = (payload.get("id") or "").strip() or f"custom_{uuid.uuid4().hex[:8]}"
            data = _load_file(filename)
            if any(c.get("id") == card_id for c in data):
                return self._json({"error": "Bu ID zaten var"}, 409)
            card = _payload_to_entry(payload, card_id)
            card, _ = normalize_card(card)
            data.append(card)
            _save_file(filename, data)
            card["_file"] = filename
            return self._json(card, 201)

        if parsed.path == "/api/normalize-all":
            changed = 0
            for filename in (DECK_FILE, PROP_FILE):
                data = _load_file(filename)
                for i, card in enumerate(data):
                    updated, did = normalize_card(card)
                    data[i] = updated
                    if did:
                        changed += 1
                _save_file(filename, data)
            return self._json({"changed": changed})

        return self._json({"error": "Not found"}, 404)

    def do_PUT(self) -> None:
        parsed = urlparse(self.path)
        if not parsed.path.startswith("/api/cards/"):
            return self._json({"error": "Not found"}, 404)
        card_id = unquote(parsed.path.split("/api/cards/", 1)[1])
        filename = _file_for_id(card_id)
        idx = _find_index(filename, card_id)
        if idx is None:
            return self._json({"error": "Kart bulunamadı"}, 404)
        payload = self._read_json()
        data = _load_file(filename)
        card = _payload_to_entry(payload, card_id)
        card, _ = normalize_card(card)
        data[idx] = card
        _save_file(filename, data)
        card["_file"] = filename
        return self._json(card)

    def do_DELETE(self) -> None:
        parsed = urlparse(self.path)
        if not parsed.path.startswith("/api/cards/"):
            return self._json({"error": "Not found"}, 404)
        card_id = unquote(parsed.path.split("/api/cards/", 1)[1])
        filename = _file_for_id(card_id)
        data = _load_file(filename)
        before = len(data)
        data = [c for c in data if c.get("id") != card_id]
        if len(data) == before:
            return self._json({"error": "Kart bulunamadı"}, 404)
        _save_file(filename, data)
        return self._json({"ok": True})

    def _serve_static(self, name: str, content_type: str) -> None:
        path = STATIC / name
        if not path.exists():
            self.send_error(404)
            return
        data = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        if name.endswith(".html"):
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.end_headers()
        self.wfile.write(data)


def main() -> None:
    print(f"Soru Yönetimi → http://127.0.0.1:{PORT}")
    print(f"JSON: {RESOURCES}")
    Timer(0.8, lambda: webbrowser.open(f"http://127.0.0.1:{PORT}")).start()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nKapatıldı.")


if __name__ == "__main__":
    main()
