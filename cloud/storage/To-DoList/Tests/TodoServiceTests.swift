import XCTest
@testable import To_Do_List

/// Test stubs for critical business logic.
final class TodoServiceTests: XCTestCase {

    func testCreateTodo_EmptyTitle_ThrowsValidationError() async throws {
        let repo = InMemoryTodoRepository(seed: [])
        let service = TodoService(repository: repo)

        do {
            _ = try await service.createTodo(title: "   ")
            XCTFail("Expected validation error")
        } catch let error as TodoValidationError {
            XCTAssertEqual(error, .emptyTitle)
        }
    }

    func testToggleComplete_SetsCompletedAt() async throws {
        let now = Date()
        let seed = TodoItem(
            id: UUID(),
            title: "Test",
            notes: nil,
            isCompleted: false,
            createdAt: now,
            dueDate: nil,
            reminderDate: nil,
            completedAt: nil
        )
        let repo = InMemoryTodoRepository(seed: [seed])
        let service = TodoService(repository: repo)

        let updated = try await service.toggleComplete(id: seed.id, now: now)
        XCTAssertTrue(updated.isCompleted)
        XCTAssertEqual(updated.completedAt, now)
    }

    func testUpdateTodo_NotFound_Throws() async throws {
        let repo = InMemoryTodoRepository(seed: [])
        let service = TodoService(repository: repo)

        do {
            _ = try await service.updateTodo(
                id: UUID(),
                title: "A",
                notes: nil,
                dueDate: nil,
                reminderDate: nil,
                isCompleted: false
            )
            XCTFail("Expected notFound")
        } catch let error as TodoPersistenceError {
            XCTAssertEqual(error, .notFound)
        }
    }
}
