import Foundation

class LocalJSONStore {
    static let shared = LocalJSONStore()

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    init(directory: URL? = nil) {
        documentsDirectory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func save<T: Encodable>(_ data: T, to filename: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: fileURL, options: .atomic)
    }

    func load<T: Decodable>(from filename: String, as type: T.Type) throws -> T {
        let data = try loadRawData(from: filename)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    func loadRawData(from filename: String) throws -> Data {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        return try Data(contentsOf: fileURL)
    }

    func saveRawData(_ data: Data, to filename: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL, options: .atomic)
    }

    /// Encode all values before calling this method. Restore earlier files if a write fails.
    func saveBatch(_ files: [String: Data]) throws {
        var originals: [String: Data] = [:]
        for filename in files.keys where fileExists(filename) {
            originals[filename] = try loadRawData(from: filename)
        }
        var written: [String] = []
        do {
            for filename in files.keys.sorted() {
                try saveRawData(files[filename]!, to: filename)
                written.append(filename)
            }
        } catch {
            let writeError = error
            do {
                for filename in written.reversed() {
                    if let data = originals[filename] {
                        try saveRawData(data, to: filename)
                    } else {
                        try delete(filename)
                    }
                }
            } catch {
                throw LocalDataError.invalid("Kayıt ve geri alma tamamlanamadı. Mevcut yedeğinizi koruyun: \(error.localizedDescription)")
            }
            throw writeError
        }
    }

    func fileExists(_ filename: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    func delete(_ filename: String) throws {
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try fileManager.removeItem(at: fileURL)
    }

    func exportData<T: Encodable>(_ data: T) throws -> URL {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent("export_\(UUID().uuidString).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: tempURL, options: .atomic)
        return tempURL
    }

    func importData<T: Decodable>(from url: URL, as type: T.Type) throws -> T {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size <= 50 * 1024 * 1024 else {
            throw LocalDataError.invalid("JSON dosyası çok büyük. En fazla 50 MB içe aktarılabilir.")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
