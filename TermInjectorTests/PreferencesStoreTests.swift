import XCTest
@testable import TermInjector

final class PreferencesStoreTests: XCTestCase {

    private var suiteName: String!
    private var testDefaults: UserDefaults!
    private var store: PreferencesStore!

    override func setUp() {
        super.setUp()
        suiteName = "PreferencesStoreTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        store = PreferencesStore(defaults: testDefaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - デフォルト値

    func testDefaultValues() {
        XCTAssertTrue(store.sendOnEnter)
        XCTAssertFalse(store.sendOnShiftEnter)
        XCTAssertFalse(store.sendOnCmdEnter)
        XCTAssertTrue(store.safetyCheck)
        XCTAssertTrue(store.closeAfterSend)
    }

    // MARK: - 送信キー読み書き

    func testReadWrite_sendOnEnter() {
        store.sendOnEnter = false
        XCTAssertFalse(store.sendOnEnter)
        store.sendOnEnter = true
        XCTAssertTrue(store.sendOnEnter)
    }

    func testReadWrite_sendOnShiftEnter() {
        store.sendOnShiftEnter = true
        XCTAssertTrue(store.sendOnShiftEnter)
        store.sendOnShiftEnter = false
        XCTAssertFalse(store.sendOnShiftEnter)
    }

    func testReadWrite_sendOnCmdEnter() {
        store.sendOnCmdEnter = true
        XCTAssertTrue(store.sendOnCmdEnter)
        store.sendOnCmdEnter = false
        XCTAssertFalse(store.sendOnCmdEnter)
    }

    // MARK: - その他の設定

    func testReadWrite_safetyCheck() {
        store.safetyCheck = false
        XCTAssertFalse(store.safetyCheck)
    }

    func testReadWrite_closeAfterSend() {
        store.closeAfterSend = false
        XCTAssertFalse(store.closeAfterSend)
    }

    // MARK: - 送信キーの独立性

    func testSendKeys_Independent() {
        // 各送信キーの設定は互いに影響しない
        store.sendOnEnter = false
        store.sendOnShiftEnter = true
        store.sendOnCmdEnter = true

        XCTAssertFalse(store.sendOnEnter)
        XCTAssertTrue(store.sendOnShiftEnter)
        XCTAssertTrue(store.sendOnCmdEnter)
    }

    // MARK: - toKeyHandlingPreferences

    func testToKeyHandlingPreferences() {
        store.sendOnEnter = false
        store.sendOnShiftEnter = true
        store.sendOnCmdEnter = true
        store.closeAfterSend = false

        let prefs = store.toKeyHandlingPreferences()

        XCTAssertFalse(prefs.sendOnEnter)
        XCTAssertTrue(prefs.sendOnShiftEnter)
        XCTAssertTrue(prefs.sendOnCmdEnter)
        XCTAssertFalse(prefs.closeAfterSend)
    }

    // MARK: - 許可アプリ設定

    func testDefaultAllowedApps() {
        // デフォルトではTerminal.appのみ
        let apps = store.allowedApps
        XCTAssertEqual(apps.count, 1)
        XCTAssertEqual(apps.first?.bundleID, Constants.terminalBundleID)
        XCTAssertEqual(apps.first?.name, "Terminal")
    }

    func testAddAllowedApp() {
        store.addAllowedApp(AllowedApp(bundleID: "com.googlecode.iterm2", name: "iTerm"))
        let apps = store.allowedApps
        XCTAssertEqual(apps.count, 2)
        XCTAssertEqual(apps[1].bundleID, "com.googlecode.iterm2")
        XCTAssertEqual(apps[1].name, "iTerm")
    }

    func testAddDuplicateApp_IsIgnored() {
        store.addAllowedApp(AllowedApp(bundleID: Constants.terminalBundleID, name: "Terminal"))
        XCTAssertEqual(store.allowedApps.count, 1)
    }

    func testRemoveAllowedApp() {
        store.addAllowedApp(AllowedApp(bundleID: "com.googlecode.iterm2", name: "iTerm"))
        XCTAssertEqual(store.allowedApps.count, 2)

        store.removeAllowedApp(bundleID: "com.googlecode.iterm2")
        XCTAssertEqual(store.allowedApps.count, 1)
        XCTAssertEqual(store.allowedApps.first?.bundleID, Constants.terminalBundleID)
    }

    func testRemoveLastApp_AllowsEmptyList() {
        store.removeAllowedApp(bundleID: Constants.terminalBundleID)
        XCTAssertTrue(store.allowedApps.isEmpty)
    }

    func testIsAllowedApp_NilBundleID_ReturnsFalse() {
        XCTAssertFalse(store.isAllowedApp(bundleID: nil))
    }

    func testIsAllowedApp_UnknownBundleID_ReturnsFalse() {
        XCTAssertFalse(store.isAllowedApp(bundleID: "com.unknown.app"))
    }

    func testAllowedBundleIDs_ReturnsSet() {
        store.addAllowedApp(AllowedApp(bundleID: "com.googlecode.iterm2", name: "iTerm"))
        let ids = store.allowedBundleIDs
        XCTAssertEqual(ids, Set(["com.apple.Terminal", "com.googlecode.iterm2"]))
    }
}
