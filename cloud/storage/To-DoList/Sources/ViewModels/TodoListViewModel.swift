import Foundation
import Combine

/// Main view model for listing, filtering, and mutating to-do items.
///
/// MVVM responsibilities:
/// - Loads tasks from the service
/// - Exposes bindable state for SwiftUI
/// - Applies UI-level filtering/sorting
@MainActor
public final class TodoListViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published public private(set) var items: [TodoItem] = []
    @Published public var filter: TodoFilter = .all
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let service: TodoService
    private let reminderManager: ReminderManaging

    public init(service: TodoService, reminderManager: ReminderManaging) {
        self.service = service
        self.reminderManager = reminderManager
    }

    // MARK: - Derived Data

    public var filteredItems: [TodoItem] {
        let base: [TodoItem]
        switch filter {
        case .all:
            base = items
        case .active:
            base = items.filter { !$0.isCompleted }
        case .completed:
            base = items.filter { $0.isCompleted }
        }

        // Sort by: incomplete first, then due date, then creation.
        return base.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            switch ($0.dueDate, $1.dueDate) {
            case let (a?, b?): return a < b
            case (_?, nil): return true
            case (nil, _?): return false
            default: return $0.createdAt < $1.createdAt
            }
        }
    }

    // MARK: - Intent(s)

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await service.loadTodos()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    public func add(title: String) async {
        errorMessage = nil
        do {
            let created = try await service.createTodo(title: title)
            items.append(created)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    public func toggleCompletion(for id: TodoItem.ID) async {
        errorMessage = nil
        do {
            let updated = try await service.toggleComplete(id: id)
            if let idx = items.firstIndex(where: { $0.id == id }) {
                items[idx] = updated
            } else {
                // If local state is stale, reload.
                await load()
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    public func delete(at offsets: IndexSet) async {
        errorMessage = nil
        let idsToDelete = offsets.compactMap { idx in
            guard filteredItems.indices.contains(idx) else { return nil }
            return filteredItems[idx].id
        }

        do {
            for id in idsToDelete {
                try await service.deleteTodo(id: id)
                await reminderManager.cancelReminder(for: id)
                items.removeAll { $0.id == id }
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    /// Call when an editor screen saved an item.
    public func upsert(_ item: TodoItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
        } else {
            items.append(item)
        }
    }
}