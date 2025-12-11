import Foundation

/// Represents a free-form label that can be attached to todo items.
/// Tags support many-to-many relationships between items and tags.
public struct TodoTag: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var colorHex: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
