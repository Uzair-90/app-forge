import Foundation

/// In-memory repository primarily intended for tests and SwiftUI previews.
public actor InMemoryTodoRepository: TodoRepository {

    private var items: [TodoItem]

    public init(seed: [TodoItem] = []) {
        self.items = seed
    }

    public func fetchAll() async throws -> [TodoItem] {
        items
    }

    public func create(_ item: TodoItem) async throws {
        if items.contains(where: { $0.id == item.id }) {
            throw TodoPersistenceError.duplicateID
        }
        items.append(item)
    }

    public func update(_ item: TodoItem) async throws {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
            throw TodoPersistenceError.notFound
        }
        items[idx] = item
    }

    public func delete(id: TodoItem.ID) async throws {
        let before = items.count
        items.removeAll { $0.id == id }
        guard items.count != before else {
            throw TodoPersistenceError.notFound
        }
    }

    public func deleteAll() async throws {
        items.removeAll()
    }
}
