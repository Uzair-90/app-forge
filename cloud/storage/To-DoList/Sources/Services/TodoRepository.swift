import Foundation

/// Abstraction for task persistence and retrieval.
///
/// This repository is intentionally UI-agnostic and can be backed by different storage engines
/// (e.g., JSON on disk, CoreData, CloudKit). View models and managers should depend on this
/// protocol rather than concrete implementations.
public protocol TodoRepository {
    /// Returns all todo items.
    func fetchAll() async throws -> [TodoItem]

    /// Inserts a new item.
    func create(_ item: TodoItem) async throws

    /// Updates an existing item.
    func update(_ item: TodoItem) async throws

    /// Deletes an item by its identifier.
    func delete(id: TodoItem.ID) async throws

    /// Deletes all items (useful for tests / debug tooling).
    func deleteAll() async throws
}
