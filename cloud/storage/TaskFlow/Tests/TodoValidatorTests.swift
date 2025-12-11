import XCTest
@testable import TaskFlow

final class TodoValidatorTests: XCTestCase {

    func testValidateTitleRejectsEmpty() {
        XCTAssertThrowsError(try TodoValidator.validateTitle("   ")) { error in
            XCTAssertEqual(error as? ValidationError, .emptyTitle)
        }
    }

    func testValidateTitleAcceptsValid() throws {
        XCTAssertNoThrow(try TodoValidator.validateTitle("Buy milk"))
    }

    func testValidateDueDateRejectsPast() {
        let past = Date().addingTimeInterval(-3600)
        XCTAssertThrowsError(try TodoValidator.validateDueDate(past)) { error in
            XCTAssertEqual(error as? ValidationError, .invalidDueDate)
        }
    }
}
