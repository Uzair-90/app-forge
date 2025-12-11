import Foundation

/// Protocol abstraction for the todo storage service used by higher layers.
/// The project already defines `TodoStorageService` implementation; this
/// protocol allows view models and repositories to depend on an interface.
public protocol TodoStorageServiceProtocol {
    /// Loads all todo items from persistence.
    func load() async throws -> [TodoItem]

    /// Persists all todo items.
    func save(_ items: [TodoItem]) async throws
}
