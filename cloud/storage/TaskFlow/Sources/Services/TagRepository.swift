import Foundation

public protocol TagRepositoryProtocol {
    func loadTags() async throws -> [TodoTag]
    func saveTags(_ tags: [TodoTag]) async throws
    func createTag(name: String, colorHex: String?) async throws -> TodoTag
    func updateTag(_ tag: TodoTag, name: String, colorHex: String?) async throws -> TodoTag
}

public final class TagRepository: TagRepositoryProtocol {

    public enum Error: LocalizedError {
        case tagNotFound

        public var errorDescription: String? {
            switch self {
            case .tagNotFound:
                return "The requested tag could not be found."
            }
        }
    }

    private let userDefaults: UserDefaults
    private let key = "taskflow.tags.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let clock: () -> Date

    public init(userDefaults: UserDefaults = .standard, clock: @escaping () -> Date = Date.init) {
        self.userDefaults = userDefaults
        self.clock = clock
    }

    public func loadTags() async throws -> [TodoTag] {
        if let data = userDefaults.data(forKey: key) {
            return try decoder.decode([TodoTag].self, from: data)
        } else {
            return []
        }
    }

    public func saveTags(_ tags: [TodoTag]) async throws {
        let data = try encoder.encode(tags)
        userDefaults.set(data, forKey: key)
    }

    public func createTag(name: String, colorHex: String?) async throws -> TodoTag {
        try TodoValidator.validateTagName(name)
        var tags = try await loadTags()
        let now = clock()
        let tag = TodoTag(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: colorHex,
            createdAt: now,
            updatedAt: now
        )
        tags.append(tag)
        try await saveTags(tags)
        return tag
    }

    public func updateTag(_ tag: TodoTag, name: String, colorHex: String?) async throws -> TodoTag {
        try TodoValidator.validateTagName(name)
        var tags = try await loadTags()
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            throw Error.tagNotFound
        }
        var updated = tags[index]
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.colorHex = colorHex
        updated.updatedAt = clock()
        tags[index] = updated
        try await saveTags(tags)
        return updated
    }
}
