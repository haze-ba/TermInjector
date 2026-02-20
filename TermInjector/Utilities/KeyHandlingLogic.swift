import Carbon.HIToolbox

/// キー入力の判定結果
enum KeyAction: Equatable {
    /// テキストを送信する
    case send
    /// 改行を挿入する
    case newline
    /// ウィンドウを閉じる
    case close
    /// IMEに処理を委譲する（変換確定等）
    case passToIME
    /// デフォルトのNSTextView処理に委譲する
    case passToSuper
}

/// キー入力に対するアクション判定の純粋関数群
enum KeyHandlingLogic {

    struct KeyEvent: Equatable {
        let keyCode: UInt16
        let modifiers: Modifiers
        let hasMarkedText: Bool

        struct Modifiers: OptionSet, Equatable {
            let rawValue: UInt
            static let shift   = Modifiers(rawValue: 1 << 0)
            static let command = Modifiers(rawValue: 1 << 1)
            static let option  = Modifiers(rawValue: 1 << 2)
            static let control = Modifiers(rawValue: 1 << 3)
        }
    }

    struct Preferences: Equatable {
        var enterSend: Bool = true
        var cmdEnterSend: Bool = false
        var cmdEnterForced: Bool = false
        var shiftEnterNewline: Bool = true
        var pasteOnly: Bool = false
        var closeAfterSend: Bool = true
    }

    // キーコード定数
    static let enterKeyCode: UInt16 = 36
    static let returnKeyCode: UInt16 = 76  // テンキーのEnter
    static let escapeKeyCode: UInt16 = 53
    static let tabKeyCode: UInt16 = 48

    /// キーイベントと設定から適切なアクションを判定する
    static func determineAction(event: KeyEvent, preferences: Preferences) -> KeyAction {
        let keyCode = event.keyCode
        let modifiers = event.modifiers

        // Escape → 常にクローズ
        if keyCode == escapeKeyCode {
            return .close
        }

        // Enter/Returnキー以外はスーパーに委譲
        guard keyCode == enterKeyCode || keyCode == returnKeyCode else {
            return .passToSuper
        }

        // IME変換中（marked text あり）→ IMEに委譲
        if event.hasMarkedText {
            return .passToIME
        }

        // Cmd+Enter
        if modifiers.contains(.command) {
            if preferences.cmdEnterForced {
                // cmdEnterForced: Cmd+Enterは常に送信（pasteOnlyでも送信）
                return .send
            }
            if preferences.cmdEnterSend {
                return .send
            }
            // Cmd+Enterが送信でない場合は改行
            return .newline
        }

        // Shift+Enter
        if modifiers.contains(.shift) {
            if preferences.shiftEnterNewline {
                return .newline
            }
            // shiftEnterNewlineが無効でも、改行として扱う
            return .newline
        }

        // 素のEnter
        if preferences.pasteOnly {
            // pasteOnlyモード: Enterは改行
            return .newline
        }

        if preferences.enterSend {
            return .send
        }

        // enterSend が false の場合、改行
        return .newline
    }
}
