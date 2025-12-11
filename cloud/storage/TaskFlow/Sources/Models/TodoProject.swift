import Foundation

/// Represents a logical grouping of todo items within TaskFlow.
/// Examples: "Work", "Personal", "Side Project".
public struct TodoProject: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var colorHex: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}

public extension TodoProject {
    /// A default inbox project used when no explicit project is selected.
    static let inbox = TodoProject(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
        name: "Inbox",
        colorHex: nil,
        createdAt: Date(),
        updatedAt: Date(),
        isArchived: false
    )
}
