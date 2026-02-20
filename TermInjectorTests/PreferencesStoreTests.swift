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
}
