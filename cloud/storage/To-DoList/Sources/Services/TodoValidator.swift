import Foundation

/// Centralized validation logic for `TodoItem` creation and updates.
///
/// Keeping validation here prevents duplication across view models and services.
public struct TodoValidator {
    public let maxTitleLength: Int
    public let maxNotesLength: Int
    public let calendar: Calendar

    public init(
        maxTitleLength: Int = 120,
        maxNotesLength: Int = 4_000,
        calendar: Calendar = .current
    ) {
        self.maxTitleLength = maxTitleLength
        self.maxNotesLength = maxNotesLength
        self.calendar = calendar
    }

    /// Validates input fields.
    public func validate(title: String, notes: String?, dueDate: Date?, now: Date = Date()) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { throw TodoValidationError.emptyTitle }
        guard trimmedTitle.count <= maxTitleLength else { throw TodoValidationError.titleTooLong(max: maxTitleLength) }

        if let notes, notes.count > maxNotesLength {
            throw TodoValidationError.notesTooLong(max: maxNotesLength)
        }

        if let dueDate {
            // Allow today at any time; only reject strictly earlier than now.
            if dueDate < now {
                throw TodoValidationError.dueDateInPast
            }
        }
    }
}
