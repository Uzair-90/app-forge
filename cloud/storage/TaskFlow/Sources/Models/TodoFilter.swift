import Foundation

struct TodoFilter: Equatable {
    enum Segment: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case completed = "Completed"

        var id: String { rawValue }
    }

    var searchText: String = ""
    var segment: Segment = .all
    var selectedCategory: TodoItem.Category? = nil
    var showCompleted: Bool = true
}
