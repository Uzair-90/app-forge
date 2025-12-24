import Foundation

/// A single task in the To-Do List application.
///
/// The model is designed to support:
/// - Basic CRUD
/// - Completion tracking
/// - Optional due dates
/// - Optional reminders (local notifications)
public struct TodoItem: Identifiable, Codable, Equatable, Hashable {

    public typealias ID = UUID

    // MARK: - Core

    public var id: ID
    public var title: String
    public var notes: String?
    public var isCompleted: Bool

    // MARK: - Timestamps

    public var createdAt: Date
    public var dueDate: Date?
    public var reminderDate: Date?
    public var completedAt: Date?

    public init(
        id: ID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        reminderDate: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.completedAt = completedAt
    }
}