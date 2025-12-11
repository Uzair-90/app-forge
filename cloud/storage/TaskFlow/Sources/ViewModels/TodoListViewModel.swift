import Foundation
import Combine

@MainActor
final class TodoListViewModel: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published var filter: TodoFilter = TodoFilter()
    @Published var showingAddSheet: Bool = false
    @Published var editingItem: TodoItem? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository: TodoRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: TodoRepositoryProtocol) {
        self.repository = repository
        Task {
            await load()
        }
        setupBindings()
    }

    var filteredItems: [TodoItem] {
        var result = items

        if !filter.showCompleted {
            result = result.filter { !$0.isCompleted }
        }

        switch filter.segment {
        case .all:
            break
        case .today:
            let calendar = Calendar.current
            result = result.filter { item in
                guard let due = item.dueDate else { return false }
                return calendar.isDateInToday(due)
            }
        case .upcoming:
            let now = Date()
            result = result.filter { item in
                guard let due = item.dueDate else { return false }
                return due > now && !Calendar.current.isDateInToday(due)
            }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        if let category = filter.selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !filter.searchText.isEmpty {
            let search = filter.searchText.lowercased()
            result = result.filter { item in
                item.title.lowercased().contains(search) ||
                item.notes.lowercased().contains(search)
            }
        }

        return result.sorted(by: sortItems(_:_:))
    }

    @discardableResult
    func add(_ draft: TodoDraft) async -> TodoItem? {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title cannot be empty."
            return nil
        }

        isLoading = true
        errorMessage = nil

        do {
            let created = try await repository.createTodo(
                title: trimmedTitle,
                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: draft.dueDate,
                isFlagged: false,
                project: nil,
                tags: []
            )

            var item = created
            item.priority = draft.priority
            item.category = draft.category
            item.hasTime = draft.hasTime

            items.append(item)
            return item
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to add task."
            return nil
        } finally {
            isLoading = false
        }
    }

    func update(_ draft: TodoDraft) async {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let id = draft.id, let existing = items.first(where: { $0.id == id }) else {
            errorMessage = "Unable to find task to update."
            return
        }

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Title cannot be empty."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let updated = try await repository.updateTodo(
                existing,
                title: trimmedTitle,
                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines),
                dueDate: draft.dueDate,
                isCompleted: draft.isCompleted,
                isFlagged: existing.isFlagged,
                project: nil,
                tags: []
            )

            var enriched = updated
            enriched.priority = draft.priority
            enriched.category = draft.category
            enriched.hasTime = draft.hasTime
            enriched.updatedAt = Date()

            if let index = items.firstIndex(where: { $0.id == enriched.id }) {
                items[index] = enriched
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to update task."
        } finally {
            isLoading = false
        }
    }

    func delete(at offsets: IndexSet) async {
        let targets = offsets.compactMap { index in
            items.indices.contains(index) ? items[index] : nil
        }

        guard !targets.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for item in targets {
                    group.addTask {
                        try await self.repository.deleteTodo(item)
                    }
                }
                try await group.waitForAll()
            }
            items.remove(atOffsets: offsets)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to delete tasks."
        } finally {
            isLoading = false
        }
    }

    func toggleCompletion(for item: TodoItem) async {
        guard let index = items.firstIndex(of: item) else { return }

        isLoading = true
        errorMessage = nil

        do {
            let updated = try await repository.toggleCompletion(for: item)
            var enriched = updated
            enriched.updatedAt = Date()
            items[index] = enriched
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to update task."
        } finally {
            isLoading = false
        }
    }

    func delete(_ item: TodoItem) async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.deleteTodo(item)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to delete task."
        } finally {
            isLoading = false
        }
    }

    func draftForNewItem() -> TodoDraft {
        TodoDraft()
    }

    func draft(for item: TodoItem) -> TodoDraft {
        TodoDraft(item: item)
    }

    // MARK: - Private

    private func setupBindings() {
        // Items are the source of truth from the repository now,
        // so we do not automatically persist here. This publisher
        // can still be useful for reacting to in-memory changes.
        $items
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await repository.loadTodos()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Failed to load tasks."
            items = []
        }
        isLoading = false
    }

    private func sortItems(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        if lhs.isCompleted != rhs.isCompleted {
            return !lhs.isCompleted
        }
        if lhs.priority != rhs.priority {
            return lhs.priority.sortIndex < rhs.priority.sortIndex
        }
        switch (lhs.dueDate, rhs.dueDate) {
        case let (l?, r?):
            if l != r { return l < r }
        case (nil, .some):
            return false
        case (.some, nil):
            return true
        case (nil, nil):
            break
        }
        return lhs.createdAt < rhs.createdAt
    }
}

// MARK: - TodoDraft

struct TodoDraft {
    var id: UUID? = nil
    var title: String = ""
    var notes: String = ""
    var isCompleted: Bool = false
    var dueDate: Date? = nil
    var hasTime: Bool = false
    var priority: TodoItem.Priority = .medium
    var category: TodoItem.Category = .other

    init() {}

    init(item: TodoItem) {
        self.id = item.id
        self.title = item.title
        self.notes = item.notes
        self.isCompleted = item.isCompleted
        self.dueDate = item.dueDate
        self.hasTime = item.hasTime
        self.priority = item.priority
        self.category = item.category
    }

    func toTodoItem() -> TodoItem {
        let now = Date()
        return TodoItem(
            id: id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: isCompleted,
            dueDate: dueDate,
            hasTime: hasTime,
            priority: priority,
            category: category,
            createdAt: id == nil ? now : now,
            updatedAt: now
        )
    }
}

private extension TodoItem.Priority {
    var sortIndex: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}