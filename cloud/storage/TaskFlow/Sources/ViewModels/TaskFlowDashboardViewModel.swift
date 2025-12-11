import Foundation
import Combine

/// High-level dashboard view model orchestrating todos, projects, and tags for the home screen.
///
/// This view model aggregates data from the repositories and exposes read-only
/// publishers / properties for the UI. It also handles high-level operations
/// like quick-add and filtering by project.
@MainActor
public final class TaskFlowDashboardViewModel: ObservableObject {

    // MARK: - Published State

    @Published public private(set) var todos: [TodoItem] = []
    @Published public private(set) var projects: [TodoProject] = []
    @Published public private(set) var tags: [TodoTag] = []

    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var lastError: Error?

    @Published public var selectedProject: TodoProject? = nil

    // Derived state
    public var overdueTodos: [TodoItem] {
        let now = Date()
        return todos.filter { item in
            guard let due = item.dueDate else { return false }
            return !item.isCompleted && due < now
        }
    }

    public var todaysTodos: [TodoItem] {
        let calendar = Calendar.current
        return todos.filter { item in
            guard let due = item.dueDate else { return false }
            return calendar.isDateInToday(due)
        }
    }

    // MARK: - Dependencies

    private let todoRepository: TodoRepositoryProtocol
    private let projectRepository: ProjectRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol

    // MARK: - Init

    public init(
        todoRepository: TodoRepositoryProtocol,
        projectRepository: ProjectRepositoryProtocol,
        tagRepository: TagRepositoryProtocol
    ) {
        self.todoRepository = todoRepository
        self.projectRepository = projectRepository
        self.tagRepository = tagRepository
    }

    // MARK: - Loading

    /// Loads all entities in parallel and updates the published state.
    public func load() async {
        isLoading = true
        lastError = nil
        do {
            async let todosTask = todoRepository.loadTodos()
            async let projectsTask = projectRepository.loadProjects()
            async let tagsTask = tagRepository.loadTags()

            let (loadedTodos, loadedProjects, loadedTags) = try await (todosTask, projectsTask, tagsTask)

            self.todos = loadedTodos
            self.projects = loadedProjects
            self.tags = loadedTags

            if self.selectedProject == nil {
                self.selectedProject = loadedProjects.first
            }
        } catch {
            self.lastError = error
        }
        isLoading = false
    }

    // MARK: - Actions

    /// Quick-adds a new todo item to the currently selected project.
    @discardableResult
    public func quickAddTodo(title: String) async -> TodoItem? {
        do {
            let project = selectedProject
            let newItem = try await todoRepository.createTodo(
                title: title,
                notes: nil,
                dueDate: nil,
                isFlagged: false,
                project: project,
                tags: []
            )
            todos.append(newItem)
            return newItem
        } catch {
            lastError = error
            return nil
        }
    }

    public func toggleCompletion(for item: TodoItem) async {
        do {
            let updated = try await todoRepository.toggleCompletion(for: item)
            if let index = todos.firstIndex(where: { $0.id == updated.id }) {
                todos[index] = updated
            }
        } catch {
            lastError = error
        }
    }

    public func deleteTodo(_ item: TodoItem) async {
        do {
            try await todoRepository.deleteTodo(item)
            todos.removeAll { $0.id == item.id }
        } catch {
            lastError = error
        }
    }

    public func createProject(name: String, colorHex: String?) async -> TodoProject? {
        do {
            let project = try await projectRepository.createProject(name: name, colorHex: colorHex)
            projects.append(project)
            return project
        } catch {
            lastError = error
            return nil
        }
    }

    public func createTag(name: String, colorHex: String?) async -> TodoTag? {
        do {
            let tag = try await tagRepository.createTag(name: name, colorHex: colorHex)
            tags.append(tag)
            return tag
        } catch {
            lastError = error
            return nil
        }
    }
}
