import Foundation

/// Errors related to persistence operations.
public enum TodoPersistenceError: LocalizedError, Equatable {
    case notFound
    case duplicateID
    case corruptedData
    case ioFailure(underlying: String)

    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested task could not be found."
        case .duplicateID:
            return "A task with the same identifier already exists."
        case .corruptedData:
            return "Saved task data is corrupted and could not be read."
        case .ioFailure(let underlying):
            return "A storage error occurred: \(underlying)"
        }
    }
}
