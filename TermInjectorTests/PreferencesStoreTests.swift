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
        XCTAssertTrue(store.enterSend)
        XCTAssertFalse(store.cmdEnterSend)
        XCTAssertFalse(store.cmdEnterForced)
        XCTAssertTrue(store.shiftEnterNewline)
        XCTAssertFalse(store.pasteOnly)
        XCTAssertTrue(store.safetyCheck)
        XCTAssertTrue(store.closeAfterSend)
    }

    // MARK: - 読み書き

    func testReadWrite_enterSend() {
        store.enterSend = false
        XCTAssertFalse(store.enterSend)
        store.enterSend = true
        XCTAssertTrue(store.enterSend)
    }

    func testReadWrite_cmdEnterSend() {
        store.cmdEnterSend = true
        XCTAssertTrue(store.cmdEnterSend)
    }

    func testReadWrite_shiftEnterNewline() {
        store.shiftEnterNewline = false
        XCTAssertFalse(store.shiftEnterNewline)
    }

    func testReadWrite_pasteOnly() {
        store.pasteOnly = true
        XCTAssertTrue(store.pasteOnly)
    }

    func testReadWrite_safetyCheck() {
        store.safetyCheck = false
        XCTAssertFalse(store.safetyCheck)
    }

    func testReadWrite_closeAfterSend() {
        store.closeAfterSend = false
        XCTAssertFalse(store.closeAfterSend)
    }

    // MARK: - cmdEnterForced の相互排他ルール

    func testCmdEnterForced_EnablesCmd_EnterSend_DisablesEnterSend() {
        store.enterSend = true
        store.cmdEnterSend = false

        store.cmdEnterForced = true

        XCTAssertTrue(store.cmdEnterForced)
        XCTAssertTrue(store.cmdEnterSend, "cmdEnterForcedをONにするとcmdEnterSendもONになる")
        XCTAssertFalse(store.enterSend, "cmdEnterForcedをONにするとenterSendが無効になる")
    }

    func testCmdEnterForced_OffDoesNotChangeOthers() {
        store.cmdEnterSend = true
        store.enterSend = false

        store.cmdEnterForced = false

        XCTAssertFalse(store.cmdEnterForced)
        XCTAssertTrue(store.cmdEnterSend, "cmdEnterForcedをOFFにしても他の値は変わらない")
        XCTAssertFalse(store.enterSend, "cmdEnterForcedをOFFにしても他の値は変わらない")
    }

    // MARK: - toKeyHandlingPreferences

    func testToKeyHandlingPreferences() {
        store.enterSend = false
        store.cmdEnterSend = true
        store.pasteOnly = true

        let prefs = store.toKeyHandlingPreferences()

        XCTAssertFalse(prefs.enterSend)
        XCTAssertTrue(prefs.cmdEnterSend)
        XCTAssertTrue(prefs.pasteOnly)
        XCTAssertTrue(prefs.shiftEnterNewline)
        XCTAssertTrue(prefs.closeAfterSend)
    }
}
