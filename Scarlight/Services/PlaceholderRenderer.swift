import Foundation

class PlaceholderRenderer {
    static func renderText(
        _ text: String,
        actor: Player?,
        target: Player?,
        players: [Player] = [],
        duration: Int,
        phase: GamePhase,
        itemName: String? = nil
    ) -> String {
        let third = players.first(where: { $0.id != actor?.id && $0.id != target?.id })

        var result = text

        if let third {
            result = applyNamedThirdTokens(result, name: third.name)
            result = replaceRoleTokens(in: result, marker: "ÜO", name: third.name)
            result = replaceRoleTokens(in: result, marker: "{ÜO}", name: third.name)
            result = replaceRoleTokens(in: result, marker: "{UO}", name: third.name)
        } else {
            result = applyNamedThirdTokens(result, name: "diğer oyuncu")
            result = result
                .replacingOccurrences(of: "{ÜO}", with: "diğer oyuncu")
                .replacingOccurrences(of: "{UO}", with: "diğer oyuncu")
            result = replaceBareToken(in: result, marker: "ÜO", name: "diğer oyuncu")
        }

        if let target {
            result = applyNamedPartnerTokens(result, name: target.name)
            result = replaceRoleTokens(in: result, marker: "HO", name: target.name)
            result = replaceRoleTokens(in: result, marker: "{HO}", name: target.name)
            result = replaceRoleTokens(in: result, marker: "{target}", name: target.name)
        }

        if let actor {
            result = applyNamedActorTokens(result, name: actor.name)
            result = replaceRoleTokens(in: result, marker: "AO", name: actor.name)
            result = replaceRoleTokens(in: result, marker: "{AO}", name: actor.name)
            result = replaceRoleTokens(in: result, marker: "{actor}", name: actor.name)
        }

        let item = itemName ?? "seçili eşya"
        result = result
            .replacingOccurrences(of: "{eşya}", with: item)
            .replacingOccurrences(of: "{item}", with: item)

        let durationText = formatDuration(duration)
        result = result.replacingOccurrences(of: "{duration}", with: durationText)
        result = result.replacingOccurrences(of: "{phase}", with: phase.rawValue)

        return result
    }

    static func previewRender(
        _ text: String,
        duration: Int,
        phase: GamePhase = .boldQuestion,
        playerScope: CardPlayerScope = .mixed,
        itemName: String? = "kırbaç"
    ) -> String {
        let sample = CardPreviewSamples.players(for: playerScope)
        return renderText(
            text,
            actor: sample.actor,
            target: sample.target,
            players: sample.all,
            duration: duration,
            phase: phase,
            itemName: itemName
        )
    }

    static func unresolvedPlaceholders(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "\\{[^{}]+\\}", options: []) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange])
        }
    }

    static func previewWarnings(
        rawText: String,
        playerScope: CardPlayerScope
    ) -> [String] {
        var warnings: [String] = []
        let rendered = previewRender(rawText, duration: 60, playerScope: playerScope)

        for token in unresolvedPlaceholders(in: rendered) {
            warnings.append("Çözülmedi: \(token)")
        }

        if playerScope == .twoPlayers,
           textReferencesThird(rawText) {
            warnings.append("Metinde diğer oyuncu var ama kart 2 kişilik.")
        }

        return warnings
    }

    static func textReferencesTarget(_ text: String) -> Bool {
        text.contains("{partner") ||
        containsRoleMarker(text, marker: "HO") ||
        containsRoleMarker(text, marker: "{HO}") ||
        containsRoleMarker(text, marker: "{target}")
    }

    static func textReferencesThird(_ text: String) -> Bool {
        text.contains("{diğer oyuncu") ||
        containsRoleMarker(text, marker: "ÜO") ||
        containsRoleMarker(text, marker: "{ÜO}") ||
        containsRoleMarker(text, marker: "{UO}")
    }

    private static func containsRoleMarker(_ text: String, marker: String) -> Bool {
        text.range(of: marker, options: .caseInsensitive) != nil
    }

    private static func replaceRoleTokens(in text: String, marker: String, name: String) -> String {
        guard containsRoleMarker(text, marker: marker) else { return text }
        var result = text
        let apostrophes = ["'", "’", "`"]

        let suffixRules: [(suffix: String, format: (String) -> String)] = [
            ("nun", TurkishNameFormatter.genitive),
            ("nın", TurkishNameFormatter.genitive),
            ("nün", TurkishNameFormatter.genitive),
            ("nin", TurkishNameFormatter.genitive),
            ("ya", TurkishNameFormatter.dative),
            ("ye", TurkishNameFormatter.dative),
            ("yu", TurkishNameFormatter.accusative),
            ("yü", TurkishNameFormatter.accusative),
            ("yi", TurkishNameFormatter.accusative),
            ("yı", TurkishNameFormatter.accusative),
            ("nu", TurkishNameFormatter.accusative),
            ("nü", TurkishNameFormatter.accusative),
            ("ni", TurkishNameFormatter.accusative),
            ("nı", TurkishNameFormatter.accusative),
            ("yla", { n in "\(n)'yla" }),
            ("yle", { n in "\(n)'yle" })
        ]

        for apostrophe in apostrophes {
            for rule in suffixRules {
                result = result.replacingOccurrences(
                    of: "\(marker)\(apostrophe)\(rule.suffix)",
                    with: rule.format(name),
                    options: .caseInsensitive
                )
            }
        }

        result = replaceBareToken(in: result, marker: marker, name: name)
        return result
    }

    private static func replaceBareToken(in text: String, marker: String, name: String) -> String {
        guard containsRoleMarker(text, marker: marker) else { return text }
        guard let regex = try? NSRegularExpression(
            pattern: "(?i)(?<![A-Za-zğüşıöçĞÜŞİÖÇ])\(NSRegularExpression.escapedPattern(for: marker))(?!['A-Za-zğüşıöçĞÜŞİÖÇ])",
            options: []
        ) else {
            return text.replacingOccurrences(of: marker, with: name, options: .caseInsensitive)
        }

        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: NSRegularExpression.escapedTemplate(for: name))
    }

    /// Oyun ekranı: Kim→Kime başlığında isimler gösterilir; metinde isim/placeholder kalmaz.
    static func renderGameplayText(
        _ text: String,
        duration: Int,
        phase: GamePhase,
        itemName: String? = nil,
        stripDuration: Bool = false
    ) -> String {
        var result = text

        result = unwrapReadableGameplayTokens(result)
        result = applyGameplayPartnerTokens(result)
        result = applyGameplayThirdTokens(result)
        result = stripGameplayActorTokens(result)

        let item = itemName ?? "seçili eşya"
        result = result
            .replacingOccurrences(of: "{eşya}", with: item)
            .replacingOccurrences(of: "{item}", with: item)

        result = result.replacingOccurrences(of: "{duration}", with: "")
        result = result.replacingOccurrences(of: "{phase}", with: phase.rawValue)

        result = stripRemainingBraces(result)

        // Süre yalnızca sayaçta; metinde "30 saniye", "2 dakika" vb. kalmaz.
        if stripDuration {
            result = stripEmbeddedDuration(result)
        }

        return cleanupGameplaySentence(result)
    }

    static func renderSurpriseTaskText(_ text: String) -> String {
        cleanupGameplaySentence(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Gameplay token maps

    /// Okunabilir token'ları süslü parantezsiz oyuncu kelimelerine çevirir.
    private static let readableGameplayTokens: [(String, String)] = [
        ("{partnerin}", "partnerin"),
        ("{partnere}", "partnere"),
        ("{partneri}", "partneri"),
        ("{partnerle}", "partnerle"),
        ("{partner}", "partner"),
        ("{diğer oyuncunun}", "diğer oyuncunun"),
        ("{diğer oyuncuya}", "diğer oyuncuya"),
        ("{diğer oyuncuyu}", "diğer oyuncuyu"),
        ("{diğer oyuncuyla}", "diğer oyuncuyla"),
        ("{diğer oyuncu}", "diğer oyuncu")
    ]

    private static func unwrapReadableGameplayTokens(_ text: String) -> String {
        var result = text
        for (token, word) in readableGameplayTokens {
            result = result.replacingOccurrences(of: token, with: word, options: .caseInsensitive)
        }
        return result
    }

    private static let partnerTokenMap: [(String, String)] = [
        ("{HO}'nun", "partnerin"),
        ("{HO}'nın", "partnerin"),
        ("{HO}'nün", "partnerin"),
        ("{HO}'nin", "partnerin"),
        ("HO'nun", "partnerin"),
        ("HO'nın", "partnerin"),
        ("HO'nün", "partnerin"),
        ("HO'nin", "partnerin"),
        ("{HO}'ya", "partnere"),
        ("{HO}'ye", "partnere"),
        ("HO'ya", "partnere"),
        ("HO'ye", "partnere"),
        ("{HO}'yu", "partneri"),
        ("{HO}'yü", "partneri"),
        ("{HO}'yi", "partneri"),
        ("{HO}'yı", "partneri"),
        ("HO'yu", "partneri"),
        ("HO'yü", "partneri"),
        ("HO'yi", "partneri"),
        ("HO'yı", "partneri"),
        ("{HO}'yla", "partnerle"),
        ("{HO}'yle", "partnerle"),
        ("HO'yla", "partnerle"),
        ("HO'yle", "partnerle"),
        ("{HO}", "partner"),
        ("{target}", "partner")
    ]

    private static let thirdTokenMap: [(String, String)] = [
        ("{ÜO}'nun", "diğer oyuncunun"),
        ("{ÜO}'nın", "diğer oyuncunun"),
        ("{UO}'nun", "diğer oyuncunun"),
        ("ÜO'nun", "diğer oyuncunun"),
        ("ÜO'nın", "diğer oyuncunun"),
        ("{ÜO}'ya", "diğer oyuncuya"),
        ("{UO}'ya", "diğer oyuncuya"),
        ("ÜO'ya", "diğer oyuncuya"),
        ("{ÜO}'yu", "diğer oyuncuyu"),
        ("{UO}'yu", "diğer oyuncuyu"),
        ("ÜO'yu", "diğer oyuncuyu"),
        ("{ÜO}'yla", "diğer oyuncuyla"),
        ("{UO}'yla", "diğer oyuncuyla"),
        ("ÜO'yla", "diğer oyuncuyla"),
        ("{ÜO}", "diğer oyuncu"),
        ("{UO}", "diğer oyuncu")
    ]

    private static func applyGameplayPartnerTokens(_ text: String) -> String {
        var result = text
        for (token, replacement) in partnerTokenMap {
            result = result.replacingOccurrences(of: token, with: replacement, options: .caseInsensitive)
        }
        result = replaceBareToken(in: result, marker: "HO", name: "partner")
        return result
    }

    private static func applyGameplayThirdTokens(_ text: String) -> String {
        var result = text
        for (token, replacement) in thirdTokenMap {
            result = result.replacingOccurrences(of: token, with: replacement, options: .caseInsensitive)
        }
        result = replaceBareToken(in: result, marker: "ÜO", name: "diğer oyuncu")
        return result
    }

    private static func applyNamedPartnerTokens(_ text: String, name: String) -> String {
        guard text.range(of: "{partner", options: .caseInsensitive) != nil else { return text }
        var result = text
        let rules: [(String, (String) -> String)] = [
            ("{partnerin}", TurkishNameFormatter.genitive),
            ("{partnere}", TurkishNameFormatter.dative),
            ("{partneri}", TurkishNameFormatter.accusative),
            ("{partnerle}", { n in "\(n)'yla" }),
            ("{partner}", { n in n })
        ]
        for (token, format) in rules {
            result = result.replacingOccurrences(of: token, with: format(name), options: .caseInsensitive)
        }
        return result
    }

    private static func applyNamedThirdTokens(_ text: String, name: String) -> String {
        guard text.range(of: "{diğer oyuncu", options: .caseInsensitive) != nil else { return text }
        var result = text
        let rules: [(String, (String) -> String)] = [
            ("{diğer oyuncunun}", TurkishNameFormatter.genitive),
            ("{diğer oyuncuya}", TurkishNameFormatter.dative),
            ("{diğer oyuncuyu}", TurkishNameFormatter.accusative),
            ("{diğer oyuncuyla}", { n in "\(n)'yla" }),
            ("{diğer oyuncu}", { n in n })
        ]
        for (token, format) in rules {
            result = result.replacingOccurrences(of: token, with: format(name), options: .caseInsensitive)
        }
        return result
    }

    private static func applyNamedActorTokens(_ text: String, name: String) -> String {
        text.replacingOccurrences(of: "{sıradaki}", with: name, options: .caseInsensitive)
    }

    private static func stripGameplayActorTokens(_ text: String) -> String {
        var result = text

        let actorPatterns = [
            "\\{sıradaki\\}",
            "\\{AO\\}'?(nun|nın|nün|nin|ya|ye|yu|yü|yi|yı|yla|yle)",
            "AO'?(nun|nın|nün|nin|ya|ye|yu|yü|yi|yı|yla|yle)",
            "\\{actor\\}'?(nun|nın|nün|nin|ya|ye|yu|yü|yi|yı|yla|yle)",
            "\\{AO\\}",
            "\\{actor\\}"
        ]

        for pattern in actorPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }

        result = replaceBareToken(in: result, marker: "AO", name: "")
        result = replaceBareToken(in: result, marker: "actor", name: "")
        result = replaceBareToken(in: result, marker: "sıradaki", name: "")

        let leadingPatterns = [
            "^\\{sıradaki\\}\\s*,\\s*",
            "^\\{AO\\}\\s*,\\s*",
            "^AO\\s*,\\s*",
            "^\\{actor\\}\\s*,\\s*"
        ]
        for pattern in leadingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }

        if let regex = try? NSRegularExpression(pattern: "^\\s*,\\s*", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        return result
    }

    /// Kalan {…} bloklarını temizler (isim veya boş placeholder).
    private static func stripRemainingBraces(_ text: String) -> String {
        var result = text
        if let regex = try? NSRegularExpression(pattern: "\\{[^{}]*\\}", options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }
        return result
    }

    /// Metindeki gömülü süre ifadelerini kaldırır; süre sayaçta gösterilir.
    private static func stripEmbeddedDuration(_ text: String) -> String {
        var result = text
        let patterns = [
            "\\s*\\d+\\s*(?:dakika|dk)(?:\\s+\\d+\\s*(?:saniye|sn)(?:de|da)?)?(?:de|da)?",
            "\\s*\\d+\\s*(?:saniye|sn)(?:de|da)?",
            "\\s+(?:boyunca|süresince|içinde)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
            }
        }
        return result
    }

    private static func cleanupGameplaySentence(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: " ,", with: ",")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(of: " ve ve ", with: " ve ")
            .replacingOccurrences(of: " ve .", with: ".")
            .replacingOccurrences(of: " ve,", with: ",")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let regex = try? NSRegularExpression(pattern: "\\s+ve\\s*[.,]\\s*$", options: [.caseInsensitive]) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
        }

        while result.hasPrefix(",") || result.hasPrefix(".") || result.hasPrefix("ve ") {
            if result.hasPrefix("ve ") {
                result = String(result.dropFirst(3))
            } else {
                result = String(result.dropFirst())
            }
            result = result.trimmingCharacters(in: .whitespaces)
        }

        while result.hasSuffix(",") || result.hasSuffix(" ve") {
            if result.hasSuffix(" ve") {
                result = String(result.dropLast(3))
            } else {
                result = String(result.dropLast())
            }
            result = result.trimmingCharacters(in: .whitespaces)
        }

        guard !result.isEmpty else { return result }
        let turkish = Locale(identifier: "tr_TR")
        let first = result.prefix(1).uppercased(with: turkish)
        result = first + result.dropFirst()
        return result
    }

    static func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) saniye"
        } else if seconds == 60 {
            return "1 dakika"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) dakika"
            } else {
                return "\(minutes) dakika \(remainingSeconds) saniye"
            }
        }
    }
}
