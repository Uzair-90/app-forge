import Foundation
import Combine

/// View model backing task creation and editing screens.
///
/// This VM is designed to be used by editor views (e.g. `TodoEditorView`, `TaskDetailView`).
@MainActor
public final class TodoEditorViewModel: ObservableObject {

    // MARK: - Input

    @Published public var title: String
    @Published public var notes: String
    @Published public var dueDate: Date?
    @Published public var reminderDate: Date?
    @Published public var isCompleted: Bool

    // MARK: - Output

    @Published public private(set) var isSaving: Bool = false
    @Published public private(set) var errorMessage: String?

    public let editingID: TodoItem.ID?

    private let service: TodoService
    private let reminderManager: ReminderManaging

    public init(
        item: TodoItem? = nil,
        service: TodoService,
        reminderManager: ReminderManaging
    ) {
        self.editingID = item?.id
        self.title = item?.title ?? ""
        self.notes = item?.notes ?? ""
        self.dueDate = item?.dueDate
        self.reminderDate = item?.reminderDate
        self.isCompleted = item?.isCompleted ?? false
        self.service = service
        self.reminderManager = reminderManager
    }

    /// Saves changes by creating or updating a task.
    public func save() async -> TodoItem? {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            let saved: TodoItem
            if let id = editingID {
                saved = try await service.updateTodo(
                    id: id,
                    title: title,
                    notes: notes.isEmpty ? nil : notes,
                    dueDate: dueDate,
                    reminderDate: reminderDate,
                    isCompleted: isCompleted
                )
            } else {
                saved = try await service.createTodo(
                    title: title,
                    notes: notes.isEmpty ? nil : notes,
                    dueDate: dueDate,
                    reminderDate: reminderDate
                )
            }

            // Best-effort reminders.
            if saved.reminderDate != nil {
                try? await reminderManager.scheduleReminder(for: saved)
            } else {
                await reminderManager.cancelReminder(for: saved.id)
            }

            return saved
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return nil
        }
    }
}
