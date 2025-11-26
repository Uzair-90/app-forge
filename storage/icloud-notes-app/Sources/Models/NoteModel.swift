import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let folder: String
}
