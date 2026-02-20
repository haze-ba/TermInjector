import XCTest
@testable import TermInjector

final class FileDropHandlerTests: XCTestCase {

    // MARK: - processDroppedURLs

    func testProcessDroppedURLs_SingleFile() {
        let urls = [URL(fileURLWithPath: "/Users/test/file.txt")]
        let paths = FileDropHandler.processDroppedURLs(urls)
        XCTAssertEqual(paths, ["/Users/test/file.txt"])
    }

    func testProcessDroppedURLs_MultipleFiles() {
        let urls = [
            URL(fileURLWithPath: "/Users/test/a.txt"),
            URL(fileURLWithPath: "/Users/test/b.swift"),
        ]
        let paths = FileDropHandler.processDroppedURLs(urls)
        XCTAssertEqual(paths.count, 2)
        XCTAssertEqual(paths[0], "/Users/test/a.txt")
        XCTAssertEqual(paths[1], "/Users/test/b.swift")
    }

    func testProcessDroppedURLs_NonFileURL_Filtered() {
        let urls = [
            URL(string: "https://example.com/file.txt")!,
            URL(fileURLWithPath: "/Users/test/real.txt"),
        ]
        let paths = FileDropHandler.processDroppedURLs(urls)
        XCTAssertEqual(paths.count, 1)
        XCTAssertEqual(paths[0], "/Users/test/real.txt")
    }

    func testProcessDroppedURLs_Empty() {
        let paths = FileDropHandler.processDroppedURLs([])
        XCTAssertTrue(paths.isEmpty)
    }

    // MARK: - formatPaths

    func testFormatPaths_Single_NoSpecialChars() {
        let result = FileDropHandler.formatPaths(["/Users/test/file.txt"])
        XCTAssertEqual(result, "/Users/test/file.txt")
    }

    func testFormatPaths_Single_WithSpaces() {
        let result = FileDropHandler.formatPaths(["/Users/test/my file.txt"])
        XCTAssertEqual(result, "'/Users/test/my file.txt'")
    }

    func testFormatPaths_Multiple() {
        let result = FileDropHandler.formatPaths(["/a.txt", "/b.txt"])
        XCTAssertEqual(result, "/a.txt /b.txt")
    }

    func testFormatPaths_Multiple_WithSpaces() {
        let result = FileDropHandler.formatPaths(["/my dir/a.txt", "/b.txt"])
        XCTAssertEqual(result, "'/my dir/a.txt' /b.txt")
    }

    func testFormatPaths_Empty() {
        let result = FileDropHandler.formatPaths([])
        XCTAssertEqual(result, "")
    }

    // MARK: - escapePath（シェルメタ文字対策）

    func testEscapePath_SafePath_NoChange() {
        let result = FileDropHandler.escapePath("/Users/test/file.txt")
        XCTAssertEqual(result, "/Users/test/file.txt")
    }

    func testEscapePath_SpacesWrappedInSingleQuotes() {
        let result = FileDropHandler.escapePath("/Users/test/my file.txt")
        XCTAssertEqual(result, "'/Users/test/my file.txt'")
    }

    func testEscapePath_DollarSign_Escaped() {
        let result = FileDropHandler.escapePath("/Users/test/$HOME.txt")
        XCTAssertEqual(result, "'/Users/test/$HOME.txt'")
    }

    func testEscapePath_Backtick_Escaped() {
        let result = FileDropHandler.escapePath("/Users/test/`cmd`.txt")
        XCTAssertEqual(result, "'/Users/test/`cmd`.txt'")
    }

    func testEscapePath_SingleQuoteInPath_Escaped() {
        let result = FileDropHandler.escapePath("/Users/test/it's.txt")
        XCTAssertEqual(result, "'/Users/test/it'\\''s.txt'")
    }

    func testEscapePath_Parentheses_Escaped() {
        let result = FileDropHandler.escapePath("/Users/test/$(whoami).txt")
        XCTAssertEqual(result, "'/Users/test/$(whoami).txt'")
    }

    func testEscapePath_Semicolon_Escaped() {
        let result = FileDropHandler.escapePath("/Users/test/a;rm -rf.txt")
        XCTAssertEqual(result, "'/Users/test/a;rm -rf.txt'")
    }

    func testEscapePath_Pipe_Escaped() {
        let result = FileDropHandler.escapePath("/Users/test/a|b.txt")
        XCTAssertEqual(result, "'/Users/test/a|b.txt'")
    }
}
