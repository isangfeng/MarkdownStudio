import XCTest
@testable import MarkdownStudioCore

final class MarkdownOutlineTests: XCTestCase {
    func testParseAtxHeadings() {
        let outline = MarkdownOutline.parse("""
        # Title
        Body
        ## Section
        ### Detail ###
        ## C#
        """)

        XCTAssertEqual(outline, [
            MarkdownOutlineItem(level: 1, title: "Title", lineNumber: 1),
            MarkdownOutlineItem(level: 2, title: "Section", lineNumber: 3),
            MarkdownOutlineItem(level: 3, title: "Detail", lineNumber: 4),
            MarkdownOutlineItem(level: 2, title: "C#", lineNumber: 5)
        ])
    }

    func testIgnoresHeadingsInsideFencedCodeBlocks() {
        let outline = MarkdownOutline.parse("""
        # Visible
        ```
        # Hidden
        ```
        ## Also Visible
        """)

        XCTAssertEqual(outline, [
            MarkdownOutlineItem(level: 1, title: "Visible", lineNumber: 1),
            MarkdownOutlineItem(level: 2, title: "Also Visible", lineNumber: 5)
        ])
    }

    func testIgnoresInvalidHeadings() {
        let outline = MarkdownOutline.parse("""
        #Missing space
        ####### Too deep
            # Code block style indent
        """)

        XCTAssertTrue(outline.isEmpty)
    }
}
