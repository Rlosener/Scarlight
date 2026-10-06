import Foundation

/// Kart eşleştirmesi için üst düzey eşya grubu.
enum PropCategory: String, Codable, CaseIterable, Identifiable {
    case hotStimulating = "Ateşli & Uyarıcı"
    case edibleReachable = "Yenilebilir"
    case psychoStimulant = "Uyarıcı"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hotStimulating: return "flame.fill"
        case .edibleReachable: return "leaf.fill"
        case .psychoStimulant: return "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .hotStimulating:
            return "Bağlama, oyuncak, masaj ve duyusal eşyalar"
        case .edibleReachable:
            return "Yiyecek, içecek ve yenilebilir oyun malzemeleri"
        case .psychoStimulant:
            return "Psikoaktif ve güçlendirici maddeler"
        }
    }

    var subcategories: [PropSubcategory] {
        PropSubcategory.allCases.filter { $0.category == self }
    }

    static func from(packKey: String) -> PropCategory? {
        switch packKey {
        case "hotStimulating", "Ateşli & Uyarıcı": return .hotStimulating
        case "edibleReachable", "Yenilebilir ve Ulaşılabilir", "Yenilebilir": return .edibleReachable
        case "psychoStimulant", "Uyarıcı": return .psychoStimulant
        default: return PropCategory(rawValue: packKey)
        }
    }
}

/// Eşya seçim ekranında gösterilen alt kategori.
enum PropSubcategory: String, Codable, CaseIterable, Identifiable {
    case restraint = "Bağlama & Kısıtlama"
    case sensory = "Duyusal & Uyarıcı"
    case impact = "Vurma & Baskı"
    case toys = "Seks Oyuncakları"
    case massageCare = "Masaj & Bakım"
    case clothing = "Kıyafet & Aksesuar"
    case atmosphere = "Atmosfer & Dekor"
    case food = "Yiyecek"
    case drink = "İçecek"
    case edibleExtras = "Tatlı & Sos"
    case psycho = "Psikoaktif"

    var id: String { rawValue }

    var category: PropCategory {
        switch self {
        case .restraint, .sensory, .impact, .toys, .massageCare, .clothing, .atmosphere:
            return .hotStimulating
        case .food, .drink, .edibleExtras:
            return .edibleReachable
        case .psycho:
            return .psychoStimulant
        }
    }

    var icon: String {
        switch self {
        case .restraint: return "link"
        case .sensory: return "hand.raised.fill"
        case .impact: return "bolt.fill"
        case .toys: return "heart.fill"
        case .massageCare: return "drop.fill"
        case .clothing: return "tshirt.fill"
        case .atmosphere: return "light.max"
        case .food: return "carrot.fill"
        case .drink: return "wineglass.fill"
        case .edibleExtras: return "birthday.cake.fill"
        case .psycho: return "sparkles"
        }
    }
}

struct GameProp: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: PropCategory
    let subcategory: PropSubcategory

    init(id: String, name: String, category: PropCategory, subcategory: PropSubcategory) {
        self.id = id
        self.name = name
        self.category = category
        self.subcategory = subcategory
    }

    init(id: String, name: String, subcategory: PropSubcategory) {
        self.id = id
        self.name = name
        self.subcategory = subcategory
        self.category = subcategory.category
    }
}

enum PropCatalog {
    static let all: [GameProp] = hotStimulating + edibleReachable + psychoStimulant

    static let hotStimulating: [GameProp] = [
        // Bağlama & Kısıtlama
        prop("hot_0", "kelepçe", .restraint),
        prop("hot_1", "ip", .restraint),
        prop("hot_2", "göz bandı", .restraint),
        prop("hot_3", "ağız topu", .restraint),
        prop("hot_4", "tasma", .restraint),
        prop("hot_5", "dekoratif zincir", .restraint),
        prop("hot_6", "göz bağı", .restraint),
        prop("hot_7", "saten bağ", .restraint),
        prop("hot_8", "deri harness", .restraint),
        prop("hot_9", "kravat", .restraint),

        // Duyusal & Uyarıcı
        prop("hot_10", "tüy", .sensory),
        prop("hot_11", "bıçak", .sensory),
        prop("hot_12", "buz", .sensory),
        prop("hot_13", "oyun zili", .sensory),
        prop("hot_14", "tüy kırbaç", .sensory),
        prop("hot_15", "eldiven", .sensory),

        // Vurma & Baskı
        prop("hot_16", "kırbaç", .impact),
        prop("hot_17", "kemer", .impact),
        prop("hot_18", "mini kırbaç", .impact),
        prop("hot_19", "şaplak paddle", .impact),

        // Seks Oyuncakları
        prop("hot_20", "vibratör", .toys),
        prop("hot_21", "dildo", .toys),
        prop("hot_22", "strap-on", .toys),
        prop("hot_23", "penis halkası", .toys),
        prop("hot_24", "mastürbatör", .toys),
        prop("hot_25", "anal plug", .toys),
        prop("hot_26", "uzaktan kumandalı oyuncak", .toys),

        // Masaj & Bakım
        prop("hot_27", "masaj yağı", .massageCare),
        prop("hot_28", "kayganlaştırıcı", .massageCare),

        // Kıyafet & Aksesuar
        prop("hot_29", "jartiyer", .clothing),
        prop("hot_30", "file çorap", .clothing),
        prop("hot_31", "fantezi iç çamaşırı", .clothing),

        // Atmosfer & Dekor
        prop("hot_32", "mum", .atmosphere),
        prop("hot_33", "kamera", .atmosphere),
        prop("hot_34", "yastık", .atmosphere),
        prop("hot_35", "feromon sprey", .atmosphere),
    ]

    static let edibleReachable: [GameProp] = [
        // Yiyecek
        prop("ed_0", "muz", .food),
        prop("ed_1", "çilek", .food),
        prop("ed_2", "vişne", .food),
        prop("ed_3", "üzüm", .food),
        prop("ed_4", "marshmallow", .food),
        prop("ed_5", "dondurma", .food),
        prop("ed_6", "şekerleme", .food),

        // İçecek
        prop("ed_7", "alkol", .drink),

        // Tatlı & Sos
        prop("ed_8", "krem şanti", .edibleExtras),
        prop("ed_9", "bal", .edibleExtras),
        prop("ed_10", "çikolata sosu", .edibleExtras),
        prop("ed_11", "karamel sos", .edibleExtras),
        prop("ed_12", "vücut çikolatası", .edibleExtras),
        prop("ed_13", "aromalı kayganlaştırıcı", .edibleExtras),
    ]

    static let psychoStimulant: [GameProp] = [
        prop("stim_0", "ot", .psycho),
        prop("stim_1", "kokain", .psycho),
        prop("stim_2", "lsd", .psycho),
        prop("stim_3", "azdırıcı", .psycho),
        prop("stim_4", "ex", .psycho),
    ]

    static func props(for category: PropCategory) -> [GameProp] {
        all.filter { $0.category == category }
    }

    static func props(for subcategory: PropSubcategory) -> [GameProp] {
        all.filter { $0.subcategory == subcategory }
    }

    static func prop(id: String) -> GameProp? {
        all.first { $0.id == id }
    }

    static func prop(named name: String) -> GameProp? {
        all.first { $0.name.lowercased() == name.lowercased() }
    }

    private static func prop(_ id: String, _ name: String, _ subcategory: PropSubcategory) -> GameProp {
        GameProp(id: id, name: name, subcategory: subcategory)
    }
}
