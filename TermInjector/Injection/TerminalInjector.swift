import Cocoa

/// 注入結果
enum InjectionResult {
    case success
    case noAccessibility
    case targetAppNotRunning
    case injectionFailed(String)
    case safetyCheckFailed(String)
}

/// ターミナルアプリへのテキスト注入を管理する
@MainActor
final class TerminalInjector {

    private let clipboardManager: ClipboardManager
    private let terminalDetector: TerminalDetector
    private let preferencesStore: PreferencesStore

    /// 最大リトライ回数
    private let maxRetries = 3
    /// リトライ間隔（ナノ秒）
    private let retryInterval: UInt64 = 50_000_000 // 50ms

    init(
        clipboardManager: ClipboardManager = ClipboardManager(),
        terminalDetector: TerminalDetector = TerminalDetector(),
        preferencesStore: PreferencesStore = PreferencesStore()
    ) {
        self.clipboardManager = clipboardManager
        self.terminalDetector = terminalDetector
        self.preferencesStore = preferencesStore
    }

    /// テキストを送信先アプリに注入する
    /// - Parameters:
    ///   - text: 注入するテキスト
    ///   - previousApp: オーバーレイ表示前のフォアグラウンドアプリ（安全チェック用）
    func inject(text: String, previousApp: NSRunningApplication? = nil) async -> InjectionResult {
        // 1. アクセシビリティ権限チェック
        guard AccessibilityChecker.isAccessibilityEnabled() else {
            AccessibilityChecker.ensureAccessibility()
            return .noAccessibility
        }

        // 2. 送信先アプリの決定（previousAppが起動中ならそれを使う、なければTerminal.appにフォールバック）
        let targetApp: NSRunningApplication
        if let prevApp = previousApp, !prevApp.isTerminated {
            targetApp = prevApp
        } else if let terminalApp = terminalDetector.findTerminalApp() {
            targetApp = terminalApp
        } else {
            return .targetAppNotRunning
        }

        // 3. 安全チェック（設定で有効な場合）
        if preferencesStore.safetyCheck {
            if !preferencesStore.isAllowedApp(bundleID: targetApp.bundleIdentifier) {
                return .safetyCheckFailed(
                    "オーバーレイ表示前のアプリ（\(targetApp.localizedName ?? "不明")）は許可リストに登録されていません。\n設定画面で対象アプリを追加してください。"
                )
            }
        }

        // 4. クリップボード退避
        let snapshot = clipboardManager.save()

        // 5. テキストをクリップボードに設定（末尾改行を除去）
        let trimmedText = text.replacingOccurrences(of: "\\n+$", with: "", options: .regularExpression)
        guard clipboardManager.setText(trimmedText) else {
            clipboardManager.restore(snapshot, force: true)
            return .injectionFailed("クリップボードへのテキスト設定に失敗しました")
        }

        // 6. 送信先アプリのアクティブ化（リトライ対応）
        var activated = false
        for attempt in 0..<maxRetries {
            if targetApp.activate() {
                activated = true
                break
            }
            if attempt < maxRetries - 1 {
                try? await Task.sleep(nanoseconds: retryInterval)
            }
        }

        guard activated else {
            clipboardManager.restore(snapshot, force: true)
            return .injectionFailed("送信先アプリのアクティブ化に失敗しました")
        }

        // 7. 待機 → Cmd+V
        try? await Task.sleep(nanoseconds: Constants.Defaults.injectionPasteDelay)
        KeySimulator.simulatePaste()

        // 8. 待機 → Enter
        try? await Task.sleep(nanoseconds: Constants.Defaults.injectionEnterDelay)
        KeySimulator.simulateEnter()

        // 9. 待機 → クリップボード復元
        try? await Task.sleep(nanoseconds: Constants.Defaults.injectionRestoreDelay)

        // changeCountチェック: 他アプリがクリップボードを書き換えていたら復元スキップ
        let currentChangeCount = NSPasteboard.general.changeCount
        let expectedChangeCount = snapshot.changeCount + 1 // setTextで+1
        if currentChangeCount == expectedChangeCount {
            clipboardManager.restore(snapshot, force: true)
        } else {
            NSLog("[TermInjector] クリップボードが外部から変更されたため、復元をスキップしました")
        }

        return .success
    }
}
