import XCTest
@testable import Lathe

final class WindowPathSummaryTests: XCTestCase {

    func test_abbreviatePathKeepsShortPaths() {
        XCTAssertEqual(WindowPathSummary.abbreviatePath("Lathe/README.md", maxComponents: 2), "Lathe/README.md")
    }

    func test_abbreviatePathTruncatesLongPaths() {
        XCTAssertEqual(
            WindowPathSummary.abbreviatePath("developer/git-download/Lathe/README.md", maxComponents: 2),
            "…/Lathe/README.md"
        )
    }

    func test_summarizeFilePathUsesHomeRelativePath() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let summary = WindowPathSummary.summarizeFilePath("\(home)/developer/git-download/Lathe/README.ko.md")
        XCTAssertEqual(summary, "…/Lathe/README.ko.md")
    }

    func test_summarizeWebURLUsesHostAndPath() {
        let summary = WindowPathSummary.summarize(URL(string: "https://github.com/hongmono/Lathe")!)
        XCTAssertEqual(summary, "github.com/hongmono/Lathe")
    }
}

final class WindowEntryDisplayTests: XCTestCase {

    func test_displayTitleAppendsPathSummary() {
        let entry = WindowEntry(
            id: 1,
            title: "README.ko.md",
            pathSummary: "…/Lathe/README.ko.md",
            isMinimized: false
        )
        XCTAssertEqual(entry.displayTitle, "README.ko.md (…/Lathe)")
    }

    func test_displayTitleUsesTitleOnlyWhenPathIsRedundant() {
        let entry = WindowEntry(
            id: 1,
            title: "…/Lathe/README.ko.md",
            pathSummary: "…/Lathe/README.ko.md",
            isMinimized: false
        )
        XCTAssertEqual(entry.displayTitle, "…/Lathe/README.ko.md")
    }

    func test_displayTitleIsNotDisplayableWithoutTitleOrPath() {
        let entry = WindowEntry(id: 1, title: "", pathSummary: nil, isMinimized: false)
        XCTAssertFalse(entry.isDisplayable)
    }
}
