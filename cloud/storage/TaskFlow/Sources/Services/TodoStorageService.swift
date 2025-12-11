import Foundation

protocol TodoStorageServiceProtocol {
    func load() async throws -> [TodoItem]
    func save(_ items: [TodoItem]) async throws
}

/// Concrete implementation of `TodoStorageServiceProtocol` using `UserDefaults`.
///
/// This type is intentionally simple and only knows how to persist and load
/// `TodoItem` arrays. All business rules are implemented in higher layers
/// like `TodoRepository`.
public final class TodoStorageService: TodoStorageServiceProtocol {

    public enum StorageError: LocalizedError {
        case encodingFailed
        case decodingFailed

        public var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode tasks to storage."
            case .decodingFailed:
                return "Failed to decode tasks from storage."
            }
        }
    }

    private let userDefaults: UserDefaults
    private let key = "taskflow.todos.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func load() async throws -> [TodoItem] {
        if let data = userDefaults.data(forKey: key) {
            do {
                return try decoder.decode([TodoItem].self, from: data)
            } catch {
                throw StorageError.decodingFailed
            }
        } else {
            return []
        }
    }

    public func save(_ items: [TodoItem]) async throws {
        do {
            let data = try encoder.encode(items)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed
        }
    }
}