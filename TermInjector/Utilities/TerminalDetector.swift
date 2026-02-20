import Cocoa

/// Terminal.appの検出とフォアグラウンド判定を行うプロトコル（テスト用）
protocol RunningApplicationsProvider {
    func runningApplications(withBundleIdentifier: String) -> [NSRunningApplication]
}

/// デフォルトのNSWorkspace実装
final class WorkspaceApplicationsProvider: RunningApplicationsProvider {
    func runningApplications(withBundleIdentifier bundleID: String) -> [NSRunningApplication] {
        return NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    }
}

/// Terminal.appの検出・状態判定
final class TerminalDetector {

    private let provider: RunningApplicationsProvider

    init(provider: RunningApplicationsProvider = WorkspaceApplicationsProvider()) {
        self.provider = provider
    }

    /// Terminal.appのプロセスを検索する
    func findTerminalApp() -> NSRunningApplication? {
        return provider.runningApplications(withBundleIdentifier: Constants.terminalBundleID).first
    }

    /// Terminal.appが起動中か判定する
    func isTerminalRunning() -> Bool {
        return findTerminalApp() != nil
    }

    /// Terminal.appが最前面か判定する
    func isTerminalFrontmost() -> Bool {
        return findTerminalApp()?.isActive ?? false
    }

    /// Terminal.appをアクティブにする
    @discardableResult
    func activateTerminal() -> Bool {
        guard let app = findTerminalApp() else { return false }
        return app.activate()
    }
}
