import XCTest
@testable import TaskFlow

/// Test stubs for `TodoRepository`.
///
/// These tests focus on validation behavior and core CRUD flows.
final class TodoRepositoryTests: XCTestCase {

    private final class InMemoryStorage: TodoStorageServiceProtocol {
        var items: [TodoItem] = []
        var loadCalled = false
        var saveCalled = false

        func load() async throws -> [TodoItem] {
            loadCalled = true
            return items
        }

        func save(_ items: [TodoItem]) async throws {
            saveCalled = true
            self.items = items
        }
    }

    func testCreateTodoFailsOnEmptyTitle() async throws {
        let storage = InMemoryStorage()
        let repository = TodoRepository(storageService: storage)

        do {
            _ = try await repository.createTodo(
                title: "   ",
                notes: nil,
                dueDate: nil,
                isFlagged: false,
                project: nil,
                tags: []
            )
            XCTFail("Expected ValidationError.emptyTitle to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error, .emptyTitle)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testToggleCompletionUpdatesCompletedAt() async throws {
        let storage = InMemoryStorage()
        let now = Date()
        let repository = TodoRepository(storageService: storage, clock: { now })

        let item = TodoItem(
            id: UUID(),
            title: "Test",
            notes: nil,
            isCompleted: false,
            isFlagged: false,
            createdAt: now,
            updatedAt: now,
            dueDate: nil,
            projectId: nil,
            tagIds: []
        )
        storage.items = [item]

        let updated = try await repository.toggleCompletion(for: item)
        XCTAssertTrue(updated.isCompleted)
        XCTAssertEqual(updated.completedAt, now)
    }
}
