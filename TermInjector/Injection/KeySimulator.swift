import Cocoa
import Carbon.HIToolbox

/// CGEventによるキーストローク送信
enum KeySimulator {

    /// Cmd+V（ペースト）を送信する
    static func simulatePaste() {
        sendKeyEvent(keyCode: CGKeyCode(kVK_ANSI_V), flags: .maskCommand)
    }

    /// Enterキーを送信する
    static func simulateEnter() {
        sendKeyEvent(keyCode: CGKeyCode(kVK_Return), flags: [])
    }

    private static func sendKeyEvent(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            NSLog("[TermInjector] CGEvent作成に失敗しました")
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
