import Foundation

/// Abstraction for managing todo projects.
public protocol ProjectRepositoryProtocol {
    func loadProjects() async throws -> [TodoProject]
    func saveProjects(_ projects: [TodoProject]) async throws
    func createProject(name: String, colorHex: String?) async throws -> TodoProject
    func updateProject(_ project: TodoProject, name: String, colorHex: String?) async throws -> TodoProject
    func archiveProject(_ project: TodoProject) async throws -> TodoProject
}

public final class ProjectRepository: ProjectRepositoryProtocol {

    public enum Error: LocalizedError {
        case projectNotFound

        public var errorDescription: String? {
            switch self {
            case .projectNotFound:
                return "The requested project could not be found."
            }
        }
    }

    private let userDefaults: UserDefaults
    private let key = "taskflow.projects.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let clock: () -> Date

    public init(userDefaults: UserDefaults = .standard, clock: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.clock = clock
    }

    public func loadProjects() async throws -> [TodoProject] {
        if let data = userDefaults.data(forKey: key) {
            let projects = try decoder.decode([TodoProject].self, from: data)
            if projects.isEmpty {
                return [TodoProject.inbox]
            }
            return projects
        } else {
            return [TodoProject.inbox]
        }
    }

    public func saveProjects(_ projects: [TodoProject]) async throws {
        let data = try encoder.encode(projects)
        userDefaults.set(data, forKey: key)
    }

    public func createProject(name: String, colorHex: String?) async throws -> TodoProject {
        try TodoValidator.validateProjectName(name)
        var projects = try await loadProjects()
        let now = clock()
        let project = TodoProject(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            createdAt: now,
            updatedAt: now,
            isArchived: false
        )
        projects.append(project)
        try await saveProjects(projects)
        return project
    }

    public func updateProject(_ project: TodoProject, name: String, colorHex: String?) async throws -> TodoProject {
        try TodoValidator.validateProjectName(name)
        var projects = try await loadProjects()
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
            throw Error.projectNotFound
        }
        var updated = projects[index]
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.colorHex = colorHex
        updated.updatedAt = clock()
        projects[index] = updated
        try await saveProjects(projects)
        return updated
    }

    public func archiveProject(_ project: TodoProject) async throws -> TodoProject {
        var projects = try await loadProjects()
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
            throw Error.projectNotFound
        }
        var updated = projects[index]
        updated.isArchived = true
        updated.updatedAt = clock()
        projects[index] = updated
        try await saveProjects(projects)
        return updated
    }
}
