import Foundation

/// Business rules and use-cases for interacting with to-do items.
///
/// The service depends on abstractions (repository + validator) and can be tested in isolation.
public final class TodoService {

    private let repository: TodoRepository
    private let validator: TodoValidator

    public init(repository: TodoRepository, validator: TodoValidator = TodoValidator()) {
        self.repository = repository
        self.validator = validator
    }

    /// Loads all tasks.
    public func loadTodos() async throws -> [TodoItem] {
        try await repository.fetchAll()
    }

    /// Creates a new task from primitive fields.
    public func createTodo(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        now: Date = Date()
    ) async throws -> TodoItem {
        try validator.validate(title: title, notes: notes, dueDate: dueDate, now: now)

        var item = TodoItem(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes,
            isCompleted: false,
            createdAt: now,
            dueDate: dueDate,
            reminderDate: reminderDate,
            completedAt: nil
        )

        // Normalize reminder if needed.
        if let reminderDate, let dueDate, reminderDate > dueDate {
            // If reminder is set after due date, prefer due date as a safe rule.
            item.reminderDate = dueDate
        }

        try await repository.create(item)
        return item
    }

    /// Updates an existing task.
    public func updateTodo(
        id: TodoItem.ID,
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        isCompleted: Bool,
        now: Date = Date()
    ) async throws -> TodoItem {
        try validator.validate(title: title, notes: notes, dueDate: dueDate, now: now)

        let items = try await repository.fetchAll()
        guard let existing = items.first(where: { $0.id == id }) else {
            throw TodoPersistenceError.notFound
        }

        var updated = existing
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.notes = notes
        updated.dueDate = dueDate
        updated.reminderDate = reminderDate

        // Completion business rule.
        if existing.isCompleted != isCompleted {
            updated.isCompleted = isCompleted
            updated.completedAt = isCompleted ? now : nil
        }

        if let reminderDate, let dueDate, reminderDate > dueDate {
            updated.reminderDate = dueDate
        }

        try await repository.update(updated)
        return updated
    }

    /// Toggles completion state.
    public func toggleComplete(id: TodoItem.ID, now: Date = Date()) async throws -> TodoItem {
        let items = try await repository.fetchAll()
        guard let existing = items.first(where: { $0.id == id }) else {
            throw TodoPersistenceError.notFound
        }
        var updated = existing
        updated.isCompleted.toggle()
        updated.completedAt = updated.isCompleted ? now : nil
        try await repository.update(updated)
        return updated
    }

    /// Deletes a task.
    public func deleteTodo(id: TodoItem.ID) async throws {
        try await repository.delete(id: id)
    }
}
