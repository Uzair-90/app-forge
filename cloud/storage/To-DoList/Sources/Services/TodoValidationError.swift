import Foundation

/// Validation failures for creating/updating tasks.
public enum TodoValidationError: LocalizedError, Equatable {
    case emptyTitle
    case titleTooLong(max: Int)
    case notesTooLong(max: Int)
    case dueDateInPast

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Title cannot be empty."
        case .titleTooLong(let max):
            return "Title cannot exceed \(max) characters."
        case .notesTooLong(let max):
            return "Notes cannot exceed \(max) characters."
        case .dueDateInPast:
            return "Due date cannot be in the past."
        }
    }
}
