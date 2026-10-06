import Foundation

enum PartnerPairingStore {
    private static let filename = "partner_pairing.json"
    private static let store = LocalJSONStore.shared

    static func load() -> [UUID] {
        guard store.fileExists(filename),
              let ids = try? store.load(from: filename, as: [UUID].self) else {
            return []
        }
        return ids
    }

    static func save(_ partnerIds: [UUID]) {
        let unique = Array(Set(partnerIds))
        try? store.save(unique, to: filename)
    }
}
