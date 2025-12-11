import Foundation

/// High-level abstraction over todo data that coordinates storage and domain rules.
///
/// This repository should be used by view models instead of directly depending
/// on the low-level `TodoStorageService` to keep business logic centralized.
public protocol TodoRepositoryProtocol {
    /// Loads all todo items from storage.
    func loadTodos() async throws -> [TodoItem]

    /// Persists all todo items to storage.
    func saveTodos(_ items: [TodoItem]) async throws

    /// Creates a new todo item after applying validation and default values.
    func createTodo(
        title: String,
        notes: String?,
        dueDate: Date?,
        isFlagged: Bool,
        project: TodoProject?,
        tags: [TodoTag]
    ) async throws -> TodoItem

    /// Updates an existing todo item with new values after validation.
    func updateTodo(
        _ item: TodoItem,
        title: String,
        notes: String?,
        dueDate: Date?,
        isCompleted: Bool,
        isFlagged: Bool,
        project: TodoProject?,
        tags: [TodoTag]
    ) async throws -> TodoItem

    /// Deletes a todo item.
    func deleteTodo(_ item: TodoItem) async throws

    /// Toggles the completion state of the given item.
    func toggleCompletion(for item: TodoItem) async throws -> TodoItem
}

/// Concrete implementation of `TodoRepositoryProtocol` that uses a
/// `TodoStorageService` for persistence and the domain validator for rules.
public final class TodoRepository: TodoRepositoryProtocol {

    public enum RepositoryError: LocalizedError {
        case itemNotFound

        public var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "The requested task could not be found."
            }
        }
    }

    private let storageService: TodoStorageServiceProtocol
    private let clock: () -> Date

    /// - Parameters:
    ///   - storageService: Underlying persistence service.
    ///   - clock: Injectable clock for testability (defaults to `Date.init`).
    public init(
        storageService: TodoStorageServiceProtocol,
        clock: @escaping () -> Date = Date.init
    ) {
        self.storageService = storageService
        self.clock = clock
    }

    // MARK: - Loading & Saving

    public func loadTodos() async throws -> [TodoItem] {
        try await storageService.load()
    }

    public func saveTodos(_ items: [TodoItem]) async throws {
        try await storageService.save(items)
    }

    // MARK: - CRUD

    public func createTodo(
        title: String,
        notes: String?,
        dueDate: Date?,
        isFlagged: Bool,
        project: TodoProject?,
        tags: [TodoTag]
    ) async throws -> TodoItem {
        try TodoValidator.validateTitle(title)
        try TodoValidator.validateDueDate(dueDate)

        var currentItems = try await storageService.load()

        let now = clock()
        let newItem = TodoItem(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: false,
            isFlagged: isFlagged,
            createdAt: now,
            updatedAt: now,
            dueDate: dueDate,
            projectId: project?.id,
            tagIds: Set(tags.map { $0.id })
        )

        currentItems.append(newItem)
        try await storageService.save(currentItems)
        return newItem
    }

    public func updateTodo(
        _ item: TodoItem,
        title: String,
        notes: String?,
        dueDate: Date?,
        isCompleted: Bool,
        isFlagged: Bool,
        project: TodoProject?,
        tags: [TodoTag]
    ) async throws -> TodoItem {
        try TodoValidator.validateTitle(title)
        try TodoValidator.validateDueDate(dueDate)

        var currentItems = try await storageService.load()
        guard let index = currentItems.firstIndex(where: { $0.id == item.id }) else {
            throw RepositoryError.itemNotFound
        }

        var updated = currentItems[index]
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.isCompleted = isCompleted
        updated.isFlagged = isFlagged
        updated.dueDate = dueDate
        updated.projectId = project?.id
        updated.tagIds = Set(tags.map { $0.id })
        updated.updatedAt = clock()

        currentItems[index] = updated
        try await storageService.save(currentItems)
        return updated
    }

    public func deleteTodo(_ item: TodoItem) async throws {
        var currentItems = try await storageService.load()
        currentItems.removeAll { $0.id == item.id }
        try await storageService.save(currentItems)
    }

    public func toggleCompletion(for item: TodoItem) async throws -> TodoItem {
        var currentItems = try await storageService.load()
        guard let index = currentItems.firstIndex(where: { $0.id == item.id }) else {
            throw RepositoryError.itemNotFound
        }

        var updated = currentItems[index]
        updated.isCompleted.toggle()
        updated.completedAt = updated.isCompleted ? clock() : nil
        updated.updatedAt = clock()

        currentItems[index] = updated
        try await storageService.save(currentItems)
        return updated
    }
}
