import Foundation
import SwiftUI
import Combine

class PlayerSetupViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var players: [Player] = []
    @Published var partnerPlayerIds: [UUID] = []

    private let store = LocalJSONStore.shared
    private let filename = "players.json"

    private let defaultColors = [
        "#E02B3F",
        "#F2A6B3",
        "#B11226",
        "#6E1823",
        "#FF6B9D",
        "#C9184A"
    ]

    init() {
        loadPlayers()
    }

    func loadPlayers() {
        if store.fileExists(filename) {
            do {
                let loaded = try store.load(from: filename, as: [Player].self)
                try LocalDataValidation.requireUnique(loaded.map(\.id), label: "Oyuncular")
                players = loaded
            } catch {
                print("Failed to load players: \(error)")
                errorMessage = "Oyuncular okunamadı: \(error.localizedDescription)"
            }
        } else {
            players = []
        }
        syncPartnerPairing()
    }

    @discardableResult
    private func commit(_ updated: [Player]) -> Bool {
        do {
            try LocalDataValidation.requireUnique(updated.map(\.id), label: "Oyuncular")
            guard updated.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                throw LocalDataError.invalid("Oyuncu adı boş olamaz.")
            }
            try store.save(updated, to: filename)
            players = updated
            syncPartnerPairing()
            return true
        } catch {
            errorMessage = "Oyuncular kaydedilemedi: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func savePlayers() -> Bool { commit(players) }

    @discardableResult
    func addPlayer(name: String, gender: Gender, role: PlayerRole) -> Bool {
        let colorHex = defaultColors[players.count % defaultColors.count]
        let player = Player(name: name.trimmingCharacters(in: .whitespacesAndNewlines), gender: gender, role: role, colorHex: colorHex)
        return commit(players + [player])
    }

    @discardableResult
    func removePlayer(_ player: Player) -> Bool {
        commit(players.filter { $0.id != player.id })
    }

    @discardableResult
    func updatePlayer(_ player: Player) -> Bool {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else { return false }
        var updated = players
        var normalized = player
        normalized.name = player.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated[index] = normalized
        return commit(updated)
    }

    var canStartGame: Bool {
        activePlayers.count >= 2 && Set(activePlayers.map(\.id)).count == activePlayers.count
    }

    var activePlayers: [Player] {
        players.filter { $0.isActive }
    }

    var showsPartnerPairing: Bool {
        activePlayers.count == 3
    }

    var partnerPairOptions: [[UUID]] {
        guard activePlayers.count == 3 else { return [] }
        let ids = activePlayers.map(\.id)
        return [
            [ids[0], ids[1]],
            [ids[0], ids[2]],
            [ids[1], ids[2]]
        ]
    }

    func partnerPairLabel(for pair: [UUID]) -> String {
        let names = pair.compactMap { id in activePlayers.first { $0.id == id }?.name }
        guard names.count == 2 else { return "" }
        return "\(names[0]) & \(names[1])"
    }

    func isPartnerPairSelected(_ pair: [UUID]) -> Bool {
        Set(partnerPlayerIds) == Set(pair)
    }

    func selectPartnerPair(_ pair: [UUID]) {
        partnerPlayerIds = pair
        PartnerPairingStore.save(pair)
    }

    private func syncPartnerPairing() {
        let active = activePlayers
        guard active.count == 3 else {
            partnerPlayerIds = []
            if !PartnerPairingStore.load().isEmpty { PartnerPairingStore.save([]) }
            return
        }

        let activeIds = Set(active.map(\.id))
        var saved = PartnerPairingStore.load().filter { activeIds.contains($0) }

        if saved.count != 2 {
            saved = Array(active.prefix(2).map(\.id))
        }

        partnerPlayerIds = saved
        if PartnerPairingStore.load() != saved { PartnerPairingStore.save(saved) }
    }
}
