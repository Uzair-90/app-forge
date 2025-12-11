import Foundation

struct Note: Identifiable {
    var id: UUID
    var title: String
    var content: String
    var tags: [String]
    var category: String
}