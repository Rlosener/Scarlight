import Foundation

enum LocalDataError: LocalizedError {
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .invalid(let message): return message
        }
    }
}

enum LocalDataValidation {
    static func requireUnique<T: Hashable>(_ ids: [T], label: String) throws {
        guard Set(ids).count == ids.count else {
            throw LocalDataError.invalid("\(label) içinde aynı kimliğe sahip birden fazla kayıt var.")
        }
    }

    static func validateCards(_ cards: [GameCard]) throws {
        try requireUnique(cards.map(\.id), label: "Kartlar")
        for card in cards {
            guard !card.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !card.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !card.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw LocalDataError.invalid("Kart kimliği, başlığı ve metni boş olamaz.")
            }
            guard (0...3600).contains(card.durationSeconds),
                  (1...5).contains(card.intensity),
                  (card.minPlayers ?? 2) >= 2,
                  (card.maxPlayers ?? 99) >= (card.minPlayers ?? 2) else {
                throw LocalDataError.invalid("\(card.title): süre, yoğunluk veya oyuncu aralığı geçersiz.")
            }
        }
    }
}
