import Foundation

/// Disk-backed repository using JSON serialization.
///
/// Persistence strategy:
/// - Stores all tasks as a single JSON file in Application Support.
/// - Uses an actor to guarantee thread-safety.
/// - Simple, robust, and sufficient for a classic to-do list app.
public actor TodoDiskRepository: TodoRepository {

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileName: String = "todos.json",
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        self.encoder = encoder
        self.decoder = decoder

        // Store in Application Support to avoid iCloud backup issues and keep data app-private.
        let appSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        self.fileURL = appSupport.appendingPathComponent(fileName)

        // Ensure the directory exists.
        try fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)

        // Configure coding strategy.
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder.dateEncodingStrategy = .iso8601
    }

    public func fetchAll() async throws -> [TodoItem] {
        try loadFromDisk()
    }

    public func create(_ item: TodoItem) async throws {
        var items = try loadFromDisk()
        if items.contains(where: { $0.id == item.id }) {
            throw TodoPersistenceError.duplicateID
        }
        items.append(item)
        try saveToDisk(items)
    }

    public func update(_ item: TodoItem) async throws {
        var items = try loadFromDisk()
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
            throw TodoPersistenceError.notFound
        }
        items[idx] = item
        try saveToDisk(items)
    }

    public func delete(id: TodoItem.ID) async throws {
        var items = try loadFromDisk()
        let before = items.count
        items.removeAll { $0.id == id }
        guard items.count != before else {
            throw TodoPersistenceError.notFound
        }
        try saveToDisk(items)
    }

    public func deleteAll() async throws {
        try saveToDisk([])
    }

    // MARK: - Private

    private func loadFromDisk() throws -> [TodoItem] {
        do {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return []
            }
            let data = try Data(contentsOf: fileURL)
            if data.isEmpty { return [] }
            return try decoder.decode([TodoItem].self, from: data)
        } catch let decoding as DecodingError {
            throw TodoPersistenceError.corruptedData
        } catch {
            throw TodoPersistenceError.ioFailure(underlying: String(describing: error))
        }
    }

    private func saveToDisk(_ items: [TodoItem]) throws {
        do {
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw TodoPersistenceError.ioFailure(underlying: String(describing: error))
        }
    }
}
