import Foundation

/// UserDefaultsベースの設定管理
final class PreferencesStore {

    private let defaults: UserDefaults

    // UserDefaultsキー
    private enum Keys {
        static let enterSend = "enterSend"
        static let cmdEnterSend = "cmdEnterSend"
        static let cmdEnterForced = "cmdEnterForced"
        static let shiftEnterNewline = "shiftEnterNewline"
        static let pasteOnly = "pasteOnly"
        static let safetyCheck = "safetyCheck"
        static let closeAfterSend = "closeAfterSend"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.enterSend: true,
            Keys.cmdEnterSend: false,
            Keys.cmdEnterForced: false,
            Keys.shiftEnterNewline: true,
            Keys.pasteOnly: false,
            Keys.safetyCheck: true,
            Keys.closeAfterSend: true,
        ])
    }

    // MARK: - Properties

    var enterSend: Bool {
        get { defaults.bool(forKey: Keys.enterSend) }
        set { defaults.set(newValue, forKey: Keys.enterSend) }
    }

    var cmdEnterSend: Bool {
        get { defaults.bool(forKey: Keys.cmdEnterSend) }
        set { defaults.set(newValue, forKey: Keys.cmdEnterSend) }
    }

    var cmdEnterForced: Bool {
        get { defaults.bool(forKey: Keys.cmdEnterForced) }
        set {
            defaults.set(newValue, forKey: Keys.cmdEnterForced)
            // cmdEnterForcedをONにした場合、cmdEnterSendもONにする
            if newValue {
                defaults.set(true, forKey: Keys.cmdEnterSend)
                // cmdEnterForced時はenterSendを無効化（Cmd+Enterのみで送信）
                defaults.set(false, forKey: Keys.enterSend)
            }
        }
    }

    var shiftEnterNewline: Bool {
        get { defaults.bool(forKey: Keys.shiftEnterNewline) }
        set { defaults.set(newValue, forKey: Keys.shiftEnterNewline) }
    }

    var pasteOnly: Bool {
        get { defaults.bool(forKey: Keys.pasteOnly) }
        set { defaults.set(newValue, forKey: Keys.pasteOnly) }
    }

    var safetyCheck: Bool {
        get { defaults.bool(forKey: Keys.safetyCheck) }
        set { defaults.set(newValue, forKey: Keys.safetyCheck) }
    }

    var closeAfterSend: Bool {
        get { defaults.bool(forKey: Keys.closeAfterSend) }
        set { defaults.set(newValue, forKey: Keys.closeAfterSend) }
    }

    /// KeyHandlingLogic用のPreferences構造体を生成
    func toKeyHandlingPreferences() -> KeyHandlingLogic.Preferences {
        return KeyHandlingLogic.Preferences(
            enterSend: enterSend,
            cmdEnterSend: cmdEnterSend,
            cmdEnterForced: cmdEnterForced,
            shiftEnterNewline: shiftEnterNewline,
            pasteOnly: pasteOnly,
            closeAfterSend: closeAfterSend
        )
    }
}
