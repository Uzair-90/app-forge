import Foundation

/// Composition root for dependencies.
///
/// This is intentionally lightweight and can be expanded later (e.g., different repositories
/// for previews/tests, feature flags, analytics).
public struct AppContainer {
    public let repository: TodoRepository
    public let todoService: TodoService
    public let reminderManager: ReminderManaging

    public init() {
        // Disk repository can throw during initialization; fall back to an in-memory repository
        // in the rare case application support directory cannot be created.
        let repo: TodoRepository
        do {
            repo = try TodoDiskRepository()
        } catch {
            repo = InMemoryTodoRepository(seed: [])
        }

        self.repository = repo
        self.todoService = TodoService(repository: repo)
        self.reminderManager = ReminderManager()
    }

    public init(repository: TodoRepository, todoService: TodoService, reminderManager: ReminderManaging) {
        self.repository = repository
        self.todoService = todoService
        self.reminderManager = reminderManager
    }
}
