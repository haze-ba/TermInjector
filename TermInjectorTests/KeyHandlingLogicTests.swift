import XCTest
@testable import TermInjector

final class KeyHandlingLogicTests: XCTestCase {

    typealias KeyEvent = KeyHandlingLogic.KeyEvent
    typealias Preferences = KeyHandlingLogic.Preferences

    // デフォルト: sendOnEnter=true, sendOnShiftEnter=false, sendOnCmdEnter=false
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

    // MARK: - IME変換中（全キー共通: IMEに委譲）

    func testEnter_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    func testReturn_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.returnKeyCode, modifiers: [], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    func testShiftEnter_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.shift], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    func testCmdEnter_DuringIME_PassesToIME() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToIME)
    }

    // MARK: - 素のEnter

    func testEnter_SendOnEnterTrue_Sends() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .send)
    }

    func testEnter_SendOnEnterFalse_Newline() {
        var prefs = defaultPrefs
        prefs.sendOnEnter = false
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .newline)
    }

    // MARK: - Shift+Enter

    func testShiftEnter_SendOnShiftEnterFalse_Newline() {
        // デフォルト: sendOnShiftEnter=false → 改行
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.shift], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .newline)
    }

    func testShiftEnter_SendOnShiftEnterTrue_Sends() {
        var prefs = defaultPrefs
        prefs.sendOnShiftEnter = true
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.shift], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    // MARK: - Cmd+Enter

    func testCmdEnter_SendOnCmdEnterFalse_Newline() {
        // デフォルト: sendOnCmdEnter=false → 改行
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .newline)
    }

    func testCmdEnter_SendOnCmdEnterTrue_Sends() {
        var prefs = defaultPrefs
        prefs.sendOnCmdEnter = true
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    // MARK: - 複数送信キーの組み合わせ

    func testAllSendKeysEnabled_EnterSends() {
        var prefs = Preferences()
        prefs.sendOnEnter = true
        prefs.sendOnShiftEnter = true
        prefs.sendOnCmdEnter = true
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    func testAllSendKeysEnabled_ShiftEnterSends() {
        var prefs = Preferences()
        prefs.sendOnEnter = true
        prefs.sendOnShiftEnter = true
        prefs.sendOnCmdEnter = true
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.shift], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .send)
    }

    func testNoSendKeys_EnterIsNewline() {
        var prefs = Preferences()
        prefs.sendOnEnter = false
        prefs.sendOnShiftEnter = false
        prefs.sendOnCmdEnter = false
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .newline)
    }

    func testNoSendKeys_CmdEnterIsNewline() {
        var prefs = Preferences()
        prefs.sendOnEnter = false
        prefs.sendOnShiftEnter = false
        prefs.sendOnCmdEnter = false
        let event = KeyEvent(keyCode: KeyHandlingLogic.enterKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: prefs), .newline)
    }

    // MARK: - テンキーReturn

    func testReturn_Default_Sends() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.returnKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .send)
    }

    // MARK: - その他のキー

    func testOtherKey_PassesToSuper() {
        let event = KeyEvent(keyCode: 0, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToSuper)
    }

    func testTab_PassesToSuper() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.tabKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs), .passToSuper)
    }

    // MARK: - 上下矢印（履歴ナビゲーション）

    func testUpArrow_TextEmpty_ReturnsHistoryUp() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.upArrowKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: true), .historyUp)
    }

    func testUpArrow_TextNotEmpty_NotNavigating_PassesToSuper() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.upArrowKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: false, isHistoryNavigating: false), .passToSuper)
    }

    func testUpArrow_AlreadyNavigating_ReturnsHistoryUp() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.upArrowKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: false, isHistoryNavigating: true), .historyUp)
    }

    func testDownArrow_Navigating_ReturnsHistoryDown() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.downArrowKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: false, isHistoryNavigating: true), .historyDown)
    }

    func testDownArrow_NotNavigating_PassesToSuper() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.downArrowKeyCode, modifiers: [], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: false, isHistoryNavigating: false), .passToSuper)
    }

    func testUpArrow_DuringIME_PassesToSuper() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.upArrowKeyCode, modifiers: [], hasMarkedText: true)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: true), .passToSuper)
    }

    func testUpArrow_WithModifiers_PassesToSuper() {
        let event = KeyEvent(keyCode: KeyHandlingLogic.upArrowKeyCode, modifiers: [.command], hasMarkedText: false)
        XCTAssertEqual(KeyHandlingLogic.determineAction(event: event, preferences: defaultPrefs, isTextEmpty: true), .passToSuper)
    }
}
