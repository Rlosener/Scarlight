import Foundation

enum PenaltyCatalog {
    static let penaltiesFilename = "penalties.json"
    private static let mergeVersionKey = "penalty_catalog_merged_v2"

    static func loadForGameplay() -> [PenaltyCard] {
        let seed = loadSeedPenalties()
        let store = LocalJSONStore.shared

        guard store.fileExists(penaltiesFilename),
              let saved = try? store.load(from: penaltiesFilename, as: [PenaltyCard].self) else {
            try? store.save(seed, to: penaltiesFilename)
            return seed
        }

        let merged = merge(seed: seed, saved: saved)
        if !UserDefaults.standard.bool(forKey: mergeVersionKey) {
            try? store.save(merged, to: penaltiesFilename)
            UserDefaults.standard.set(true, forKey: mergeVersionKey)
        }
        return merged.filter(\.isActive)
    }

    /// Yeni seed cezaları ekler; kullanıcının aynı id ile kaydettiği cezaları korur.
    static func merge(seed: [PenaltyCard], saved: [PenaltyCard]) -> [PenaltyCard] {
        var byId = Dictionary(uniqueKeysWithValues: seed.map { ($0.id, $0) })
        for penalty in saved {
            byId[penalty.id] = penalty
        }
        return byId.values.sorted { $0.id < $1.id }
    }

    static func loadSeedPenalties() -> [PenaltyCard] {
        relatedPenalties + refusalPenalties + specialPenalties
    }

    // MARK: - İlgili (hafif alternatif — kartı kabul etmeme sebebi: cevap veremiyorum)

    private static let relatedPenalties: [PenaltyCard] = [
        PenaltyCard(
            id: "penalty_question_1",
            title: "Alternatif Soru",
            type: .related,
            relatedCategory: .question,
            intensity: 3,
            durationSeconds: 45,
            text: "Partnere itiraf tarzında bir soru sor ve cevabını dinle."
        ),
        PenaltyCard(
            id: "penalty_question_2",
            title: "Cesur İtiraf",
            type: .related,
            relatedCategory: .question,
            intensity: 3,
            durationSeconds: 60,
            text: "Partnere hiç sormadığın cesur bir soruyu sor."
        ),
        PenaltyCard(
            id: "penalty_task_1",
            title: "Hafif Solo Görev",
            type: .related,
            relatedCategory: .task,
            intensity: 3,
            durationSeconds: 45,
            text: "{partnerin} önünde yavaş dans et."
        ),
        PenaltyCard(
            id: "penalty_task_2",
            title: "Romantik Alternatif",
            type: .related,
            relatedCategory: .task,
            intensity: 3,
            durationSeconds: 60,
            text: "{partneri} romantik şekilde okşa."
        ),
    ]

    // MARK: - Red cezaları (kartı kabul etmeme — görevi yapmıyorum)

    private static let refusalPenalties: [PenaltyCard] = [
        PenaltyCard(
            id: "penalty_refusal_01",
            title: "Diz Çökme",
            type: .refusal,
            relatedCategory: .task,
            intensity: 3,
            durationSeconds: 60,
            text: "{partnerin} önünde diz çök ve göz teması kur."
        ),
        PenaltyCard(
            id: "penalty_refusal_02",
            title: "Kıyafet Cezası",
            type: .refusal,
            relatedCategory: .task,
            intensity: 3,
            durationSeconds: 45,
            text: "{partnerin} seçtiği bir kıyafet parçasını çıkar."
        ),
        PenaltyCard(
            id: "penalty_refusal_03",
            title: "Öpücük Cezası",
            type: .refusal,
            relatedCategory: .task,
            intensity: 3,
            durationSeconds: 90,
            text: "{partnerin} seçtiği 3 noktayı öp."
        ),
        PenaltyCard(
            id: "penalty_refusal_04",
            title: "Masaj Borcu",
            type: .refusal,
            relatedCategory: .task,
            intensity: 3,
            durationSeconds: 120,
            text: "{partnere} reddettiğin görev süresi kadar omuz ve boyun masajı yap."
        ),
        PenaltyCard(
            id: "penalty_refusal_05",
            title: "İtiraf Zorunluluğu",
            type: .refusal,
            relatedCategory: .question,
            intensity: 4,
            durationSeconds: 60,
            text: "{partnere} utandığın bir fantezini itiraf et."
        ),
        PenaltyCard(
            id: "penalty_refusal_06",
            title: "Kontrol Kaybı",
            type: .refusal,
            relatedCategory: .task,
            intensity: 4,
            durationSeconds: 90,
            text: "{partnerin} dokunuşlarına izin ver, kendin dokunma."
        ),
        PenaltyCard(
            id: "penalty_refusal_07",
            title: "Yatak Kenarı",
            type: .refusal,
            relatedCategory: .task,
            intensity: 4,
            durationSeconds: 120,
            text: "{partnerin} yönlendirmesiyle pasif kal, yalnızca partner okşasın."
        ),
        PenaltyCard(
            id: "penalty_refusal_08",
            title: "Çıplaklık Cezası",
            type: .refusal,
            relatedCategory: .task,
            intensity: 4,
            durationSeconds: 60,
            text: "Üstünden bir parçayı çıkar ve {partnerin} önünde dur."
        ),
        PenaltyCard(
            id: "penalty_refusal_09",
            title: "Oral Borç",
            type: .refusal,
            relatedCategory: .task,
            intensity: 5,
            durationSeconds: 120,
            text: "Reddettiğin görevin yerine {partnere} oral yap."
        ),
        PenaltyCard(
            id: "penalty_refusal_10",
            title: "Tam İtaat",
            type: .refusal,
            relatedCategory: .task,
            intensity: 5,
            durationSeconds: 180,
            text: "{partnerin} verdiği her komutu sorgusuz uygula."
        ),
        PenaltyCard(
            id: "penalty_refusal_11",
            title: "Bağlama Cezası",
            type: .refusal,
            relatedCategory: .task,
            intensity: 5,
            durationSeconds: 120,
            text: "Ellerin partner tarafından bağlansın ve yalnızca alıcı ol."
        ),
        PenaltyCard(
            id: "penalty_refusal_12",
            title: "Çift Ceza",
            type: .refusal,
            relatedCategory: .task,
            intensity: 5,
            durationSeconds: 150,
            text: "Önce {partneri} okşa, ardından {partnerin} seçtiği ceza görevini yap."
        ),
    ]

    private static let specialPenalties: [PenaltyCard] = [
        PenaltyCard(
            id: "penalty_wheel_1",
            title: "Çark Cezası",
            type: .wheel,
            relatedCategory: .wheel,
            intensity: 4,
            durationSeconds: 60,
            text: "Çarktan gelen özel ceza görevini yap."
        ),
        PenaltyCard(
            id: "penalty_partner_refusal",
            title: "Partner Reddi",
            type: .refusal,
            relatedCategory: .task,
            intensity: 4,
            durationSeconds: 90,
            text: "Partner onayını reddettiğin için {partnerin} seçtiği ceza görevini yap."
        ),
    ]
}
