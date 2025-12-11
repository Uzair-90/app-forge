import Foundation

/// Core entity representing a single task in TaskFlow.
///
/// This model is intentionally framework-agnostic and focuses on business data only.
public struct TodoItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var notes: String?

    public var isCompleted: Bool
    public var completedAt: Date?

    public var isFlagged: Bool

    public var createdAt: Date
    public var updatedAt: Date

    /// Optional due date for the task.
    public var dueDate: Date?

    /// Optional foreign key to the project this todo belongs to.
    public var projectId: UUID?

    /// Set of tag identifiers applied to this item.
    public var tagIds: Set<UUID>

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isFlagged: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dueDate: Date? = nil,
        projectId: UUID? = nil,
        tagIds: Set<UUID> = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isFlagged = isFlagged
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.projectId = projectId
        self.tagIds = tagIds
    }
}