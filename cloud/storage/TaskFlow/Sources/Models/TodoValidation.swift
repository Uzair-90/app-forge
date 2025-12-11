import Foundation

/// Errors thrown by validation logic across TaskFlow domain entities.
public enum ValidationError: LocalizedError, Equatable {
    case emptyTitle
    case titleTooLong(max: Int)
    case invalidDueDate
    case projectNameEmpty
    case projectNameTooLong(max: Int)
    case tagNameEmpty
    case tagNameTooLong(max: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Title cannot be empty."
        case .titleTooLong(let max):
            return "Title is too long. Maximum allowed is \(max) characters."
        case .invalidDueDate:
            return "Due date cannot be in the past."
        case .projectNameEmpty:
            return "Project name cannot be empty."
        case .projectNameTooLong(let max):
            return "Project name is too long. Maximum allowed is \(max) characters."
        case .tagNameEmpty:
            return "Tag name cannot be empty."
        case .tagNameTooLong(let max):
            return "Tag name is too long. Maximum allowed is \(max) characters."
        }
    }
}

/// Central place for common validation rules for the TaskFlow domain.
public enum TodoValidator {

    // MARK: - Title

    public static let maxTitleLength: Int = 200
    public static let maxProjectNameLength: Int = 80
    public static let maxTagNameLength: Int = 60

    /// Validates a todo item title.
    /// - Parameter title: The title to validate.
    /// - Throws: `ValidationError.emptyTitle` or `ValidationError.titleTooLong`.
    public static func validateTitle(_ title: String) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.emptyTitle }
        guard trimmed.count <= maxTitleLength else {
            throw ValidationError.titleTooLong(max: maxTitleLength)
        }
    }

    /// Validates a due date ensuring it's not in the past (with a small tolerance).
    /// - Parameter dueDate: The optional due date.
    /// - Throws: `ValidationError.invalidDueDate` when the date is clearly in the past.
    public static func validateDueDate(_ dueDate: Date?) throws {
        guard let dueDate else { return }
        // allow 60 seconds tolerance to avoid clock glitches
        let threshold = Date().addingTimeInterval(-60)
        guard dueDate >= threshold else { throw ValidationError.invalidDueDate }
    }

    /// Validates project name.
    public static func validateProjectName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.projectNameEmpty }
        guard trimmed.count <= maxProjectNameLength else {
            throw ValidationError.projectNameTooLong(max: maxProjectNameLength)
        }
    }

    /// Validates tag name.
    public static func validateTagName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.tagNameEmpty }
        guard trimmed.count <= maxTagNameLength else {
            throw ValidationError.tagNameTooLong(max: maxTagNameLength)
        }
    }
}
