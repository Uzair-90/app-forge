import XCTest
@testable import NotesApp

final class NotesAppTests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual(NotesApp.name, "NotesApp")
        XCTAssertEqual(NotesApp.hello(), "Hello from NotesApp!")
    }
}
