import XCTest
@testable import TermInjector

final class KeyHandlingLogicTests: XCTestCase {

    typealias KeyEvent = KeyHandlingLogic.KeyEvent
    typealias Preferences = KeyHandlingLogic.Preferences

    private let defaultPrefs = Preferences()

    // MARK: - Escape

    func testEscape_AlwaysCloses() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.escapeKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .close)
    }

    func testEscape_DuringIME_StillCloses() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.escapeKeyCode, modifiers: [], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .close)
    }

    // MARK: - IME変換中のEnter

    func testEnter_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    func testReturn_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.returnKeyCode, modifiers: [], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    func testCmdEnter_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    // MARK: - 素のEnter（デフォルト設定: enterSend=true）

    func testEnter_Default_Sends() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .send)
    }

    func testEnter_EnterSendFalse_Newline() {
        var prefs = defaultPrefs
        prefs.enterSend = false
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .newline)
    }

    // MARK: - Shift+Enter

    func testShiftEnter_Default_Newline() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.shift], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .newline)
    }

    func testShiftEnter_ShiftEnterNewlineFalse_StillNewline() {
        var prefs = defaultPrefs
        prefs.shiftEnterNewline = false
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.shift], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .newline)
    }

    // MARK: - Cmd+Enter

    func testCmdEnter_CmdEnterSendTrue_Sends() {
        var prefs = defaultPrefs
        prefs.cmdEnterSend = true
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    func testCmdEnter_CmdEnterSendFalse_Newline() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .newline)
    }

    func testCmdEnter_Forced_AlwaysSends() {
        var prefs = defaultPrefs
        prefs.cmdEnterForced = true
        prefs.pasteOnly = true // pasteOnlyでもCmd+Enter強制は送信
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    // MARK: - pasteOnlyモード

    func testEnter_PasteOnly_Newline() {
        var prefs = defaultPrefs
        prefs.pasteOnly = true
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .newline)
    }

    func testCmdEnter_PasteOnly_CmdEnterNotForced_Newline() {
        var prefs = defaultPrefs
        prefs.pasteOnly = true
        prefs.cmdEnterSend = true
        prefs.cmdEnterForced = false
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        // cmdEnterSendはtrueだが、cmdEnterForcedではないので送信
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    // MARK: - テンキーReturn

    func testReturn_Default_Sends() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.returnKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .send)
    }

    // MARK: - その他のキー

    func testOtherKey_PassesToSuper() {
        let event = KeyEvent(keyCode: 0, modifiers: [], hasMarkedText: false) // 'a'キー
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToSuper)
    }

    func testTab_PassesToSuper() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.tabKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToSuper)
    }
}
