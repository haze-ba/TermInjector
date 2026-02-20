import XCTest
@testable import TermInjector

final class TerminalDetectorTests: XCTestCase {

    // MARK: - バンドルID定数

    func testTerminalBundleID() {
        XCTAssertEqual(Constants.terminalBundleID, "com.apple.Terminal")
    }

    // MARK: - Terminal未起動時

    func testFindTerminalApp_NotRunning_ReturnsNil() {
        let provider = MockRunningApplicationsProvider(apps: [])
        let detector = TerminalDetector(provider: provider)

        XCTAssertNil(detector.findTerminalApp())
    }

    func testIsTerminalRunning_NotRunning_ReturnsFalse() {
        let provider = MockRunningApplicationsProvider(apps: [])
        let detector = TerminalDetector(provider: provider)

        XCTAssertFalse(detector.isTerminalRunning())
    }

    func testIsTerminalFrontmost_NotRunning_ReturnsFalse() {
        let provider = MockRunningApplicationsProvider(apps: [])
        let detector = TerminalDetector(provider: provider)

        XCTAssertFalse(detector.isTerminalFrontmost())
    }
}

// MARK: - Mock

private final class MockRunningApplicationsProvider: RunningApplicationsProvider {
    let apps: [NSRunningApplication]

    init(apps: [NSRunningApplication]) {
        self.apps = apps
    }

    func runningApplications(withBundleIdentifier: String) -> [NSRunningApplication] {
        return apps
    }
}
