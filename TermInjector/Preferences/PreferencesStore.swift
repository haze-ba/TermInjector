import Foundation

/// UserDefaultsベースの設定管理
final class PreferencesStore {

    private let defaults: UserDefaults

    // UserDefaultsキー
    private enum Keys {
        static let sendOnEnter = "sendOnEnter"
        static let sendOnShiftEnter = "sendOnShiftEnter"
        static let sendOnCmdEnter = "sendOnCmdEnter"
        static let safetyCheck = "safetyCheck"
        static let closeAfterSend = "closeAfterSend"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.sendOnEnter: true,
            Keys.sendOnShiftEnter: false,
            Keys.sendOnCmdEnter: false,
            Keys.safetyCheck: true,
            Keys.closeAfterSend: true,
        ])
    }

    // MARK: - 送信キー設定

    /// Enterで送信する
    var sendOnEnter: Bool {
        get { defaults.bool(forKey: Keys.sendOnEnter) }
        set { defaults.set(newValue, forKey: Keys.sendOnEnter) }
    }

    /// Shift+Enterで送信する
    var sendOnShiftEnter: Bool {
        get { defaults.bool(forKey: Keys.sendOnShiftEnter) }
        set { defaults.set(newValue, forKey: Keys.sendOnShiftEnter) }
    }

    /// Cmd+Enterで送信する
    var sendOnCmdEnter: Bool {
        get { defaults.bool(forKey: Keys.sendOnCmdEnter) }
        set { defaults.set(newValue, forKey: Keys.sendOnCmdEnter) }
    }

    // MARK: - その他の設定

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
            sendOnEnter: sendOnEnter,
            sendOnShiftEnter: sendOnShiftEnter,
            sendOnCmdEnter: sendOnCmdEnter,
            closeAfterSend: closeAfterSend
        )
    }
}
