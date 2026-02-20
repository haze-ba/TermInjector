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
        /// Enterで送信する
        var sendOnEnter: Bool = true
        /// Shift+Enterで送信する
        var sendOnShiftEnter: Bool = false
        /// Cmd+Enterで送信する
        var sendOnCmdEnter: Bool = false
        /// 送信後にウィンドウを閉じる
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
            return preferences.sendOnCmdEnter ? .send : .newline
        }

        // Shift+Enter
        if modifiers.contains(.shift) {
            return preferences.sendOnShiftEnter ? .send : .newline
        }

        // 素のEnter
        return preferences.sendOnEnter ? .send : .newline
    }
}
