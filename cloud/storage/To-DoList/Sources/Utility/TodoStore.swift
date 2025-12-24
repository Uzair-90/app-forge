import Foundation

/// Deprecated: migrated to `TodoRepository` + `TodoDiskRepository`.
///
/// This file is retained to avoid breaking references from earlier agents.
/// Prefer using `TodoService` injected via `AppContainer`.
final class TodoStore {
    private let storageKey = "todo_items_v1"

    func load() -> [TodoItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([TodoItem].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ items: [TodoItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Intentionally no-op for lightweight local persistence.
        }
    }
}