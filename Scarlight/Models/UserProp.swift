import Foundation

struct UserProp: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var subcategory: PropSubcategory

    func asGameProp() -> GameProp {
        GameProp(id: id, name: name, subcategory: subcategory)
    }
}

enum UserPropStore {
    private static let filename = "user_props.json"
    private static let store = LocalJSONStore.shared

    static func load() -> [UserProp] {
        guard store.fileExists(filename),
              let props = try? store.load(from: filename, as: [UserProp].self) else {
            return []
        }
        return props
    }

    @discardableResult
    static func add(name: String, subcategory: PropSubcategory) -> UserProp {
        var props = load()
        let prop = UserProp(
            id: "user_prop_\(UUID().uuidString.prefix(8))",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            subcategory: subcategory
        )
        props.append(prop)
        try? store.save(props, to: filename)
        return prop
    }

    static func delete(id: String) {
        var props = load()
        props.removeAll { $0.id == id }
        try? store.save(props, to: filename)
    }

    static func replace(_ props: [UserProp]) {
        try? store.save(props, to: filename)
    }
}

extension PropCatalog {
    static var allIncludingUser: [GameProp] {
        all + UserPropStore.load().map { $0.asGameProp() }
    }

    static func allProps(for category: PropCategory) -> [GameProp] {
        allIncludingUser.filter { $0.category == category }
    }

    static func allProps(for subcategory: PropSubcategory) -> [GameProp] {
        allIncludingUser.filter { $0.subcategory == subcategory }
    }

    static func resolveProp(id: String) -> GameProp? {
        prop(id: id) ?? UserPropStore.load().first(where: { $0.id == id })?.asGameProp()
    }
}
