import Foundation

/// Oyuncu isimlerine Türkçe iyelik/yönelme/belirtme eki ekler.
enum TurkishNameFormatter {
    nonisolated static func genitive(_ name: String) -> String {
        let s = pick(name, backUnrounded: "nın", backRounded: "nun", frontUnrounded: "nin", frontRounded: "nün")
        return "\(name)'\(s)"
    }

    nonisolated static func dative(_ name: String) -> String {
        if endsWithVowel(name) {
            let s = pick(name, backUnrounded: "ya", backRounded: "ya", frontUnrounded: "ye", frontRounded: "ye")
            return "\(name)'\(s)"
        }
        let s = pick(name, backUnrounded: "a", backRounded: "a", frontUnrounded: "e", frontRounded: "e")
        return "\(name)'\(s)"
    }

    nonisolated static func accusative(_ name: String) -> String {
        if endsWithVowel(name) {
            let s = pick(name, backUnrounded: "yı", backRounded: "yu", frontUnrounded: "yi", frontRounded: "yü")
            return "\(name)'\(s)"
        }
        let s = pick(name, backUnrounded: "ı", backRounded: "u", frontUnrounded: "i", frontRounded: "ü")
        return "\(name)'\(s)"
    }

    private nonisolated static func endsWithVowel(_ name: String) -> Bool {
        guard let last = name.last else { return false }
        let vowels = "aeıioöüAEIİOÖUÜ"
        return vowels.contains(last)
    }

    private nonisolated static func pick(
        _ name: String,
        backUnrounded: String,
        backRounded: String,
        frontUnrounded: String,
        frontRounded: String
    ) -> String {
        switch vowelGroup(name) {
        case .backUnrounded: return backUnrounded
        case .backRounded: return backRounded
        case .frontUnrounded: return frontUnrounded
        case .frontRounded: return frontRounded
        }
    }

    private enum VowelGroup {
        case backUnrounded, backRounded, frontUnrounded, frontRounded
    }

    private nonisolated static func vowelGroup(_ name: String) -> VowelGroup {
        for char in name.lowercased().reversed() {
            switch char {
            case "a", "ı": return .backUnrounded
            case "o", "u": return .backRounded
            case "e", "i": return .frontUnrounded
            case "ö", "ü": return .frontRounded
            default: continue
            }
        }
        return .backUnrounded
    }
}
