import Foundation

/// 許可アプリの情報
struct AllowedApp: Equatable {
    let bundleID: String
    let name: String
}

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
        static let simulateEnterAfterPaste = "simulateEnterAfterPaste"
        static let retainTextAfterSend = "retainTextAfterSend"
        static let injectionPasteDelayMs = "injectionPasteDelayMs"
        static let injectionEnterDelayMs = "injectionEnterDelayMs"
        static let injectionRestoreDelayMs = "injectionRestoreDelayMs"
        static let followTerminalWindow = "followTerminalWindow"
        static let overlayPosition = "overlayPosition"
        static let allowedApps = "allowedApps"
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
            Keys.simulateEnterAfterPaste: true,
            Keys.retainTextAfterSend: false,
            Keys.injectionPasteDelayMs: 100,
            Keys.injectionEnterDelayMs: 300,
            Keys.injectionRestoreDelayMs: 300,
            Keys.followTerminalWindow: false,
            Keys.overlayPosition: "bottom",
            Keys.allowedApps: [["bundleID": Constants.terminalBundleID, "name": "Terminal"]],
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

    /// ペースト後にEnterを送信する
    var simulateEnterAfterPaste: Bool {
        get { defaults.bool(forKey: Keys.simulateEnterAfterPaste) }
        set { defaults.set(newValue, forKey: Keys.simulateEnterAfterPaste) }
    }

    /// 送信後もテキストを保持する
    var retainTextAfterSend: Bool {
        get { defaults.bool(forKey: Keys.retainTextAfterSend) }
        set { defaults.set(newValue, forKey: Keys.retainTextAfterSend) }
    }

    // MARK: - 注入タイミング設定

    /// ペースト前の待機時間（ミリ秒）
    var injectionPasteDelayMs: Int {
        get { defaults.integer(forKey: Keys.injectionPasteDelayMs) }
        set { defaults.set(newValue, forKey: Keys.injectionPasteDelayMs) }
    }

    /// Enter前の待機時間（ミリ秒）
    var injectionEnterDelayMs: Int {
        get { defaults.integer(forKey: Keys.injectionEnterDelayMs) }
        set { defaults.set(newValue, forKey: Keys.injectionEnterDelayMs) }
    }

    /// クリップボード復元前の待機時間（ミリ秒）
    var injectionRestoreDelayMs: Int {
        get { defaults.integer(forKey: Keys.injectionRestoreDelayMs) }
        set { defaults.set(newValue, forKey: Keys.injectionRestoreDelayMs) }
    }

    /// タイミング設定をデフォルトに戻す
    func resetTimingDefaults() {
        injectionPasteDelayMs = 100
        injectionEnterDelayMs = 300
        injectionRestoreDelayMs = 300
    }

    // MARK: - ウィンドウ追従設定

    /// ターミナルウィンドウに追従する
    var followTerminalWindow: Bool {
        get { defaults.bool(forKey: Keys.followTerminalWindow) }
        set { defaults.set(newValue, forKey: Keys.followTerminalWindow) }
    }

    /// オーバーレイの配置位置（"bottom", "top", "left", "right"）
    var overlayPosition: String {
        get { defaults.string(forKey: Keys.overlayPosition) ?? "bottom" }
        set { defaults.set(newValue, forKey: Keys.overlayPosition) }
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

    // MARK: - 許可アプリ設定

    /// 許可アプリ一覧
    var allowedApps: [AllowedApp] {
        get {
            guard let array = defaults.array(forKey: Keys.allowedApps) as? [[String: String]] else {
                return []
            }
            return array.compactMap { dict in
                guard let bundleID = dict["bundleID"], let name = dict["name"] else { return nil }
                return AllowedApp(bundleID: bundleID, name: name)
            }
        }
        set {
            let array = newValue.map { ["bundleID": $0.bundleID, "name": $0.name] }
            defaults.set(array, forKey: Keys.allowedApps)
        }
    }

    /// 安全チェック用の高速参照セット
    var allowedBundleIDs: Set<String> {
        Set(allowedApps.map(\.bundleID))
    }

    /// バンドルIDが許可リストに含まれるか
    func isAllowedApp(bundleID: String?) -> Bool {
        guard let bundleID = bundleID else { return false }
        return allowedBundleIDs.contains(bundleID)
    }

    /// 許可アプリを追加（重複は無視）
    func addAllowedApp(_ app: AllowedApp) {
        var apps = allowedApps
        guard !apps.contains(where: { $0.bundleID == app.bundleID }) else { return }
        apps.append(app)
        allowedApps = apps
    }

    /// 許可アプリを削除
    func removeAllowedApp(bundleID: String) {
        var apps = allowedApps
        apps.removeAll { $0.bundleID == bundleID }
        allowedApps = apps
    }
}
