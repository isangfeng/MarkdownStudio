import XCTest
@testable import SumiCore

final class EditorLayoutTests: XCTestCase {
    func testTextContainerInsetUsesMinimumHorizontalInsetForNarrowWindows() {
        let inset = EditorLayout.textContainerInset(for: 800)

        XCTAssertEqual(inset.width, 60, accuracy: 0.001)
        XCTAssertEqual(inset.height, 40, accuracy: 0.001)
    }

    func testTextContainerInsetCentersContentForWideWindows() {
        let inset = EditorLayout.textContainerInset(for: 1400)

        XCTAssertEqual(inset.width, 290, accuracy: 0.001)
        XCTAssertEqual(inset.height, 40, accuracy: 0.001)
    }
}
