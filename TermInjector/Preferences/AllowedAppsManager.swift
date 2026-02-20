import Cocoa
import UniformTypeIdentifiers

/// 許可アプリリストの管理（SwiftUI用ObservableObject）
final class AllowedAppsManager: ObservableObject {

    @Published var apps: [AllowedApp] = []

    private let preferencesStore: PreferencesStore

    init(preferencesStore: PreferencesStore = PreferencesStore()) {
        self.preferencesStore = preferencesStore
        self.apps = preferencesStore.allowedApps
    }

    /// 許可アプリを削除
    func remove(bundleID: String) {
        preferencesStore.removeAllowedApp(bundleID: bundleID)
        apps = preferencesStore.allowedApps
    }

    /// NSOpenPanelで.appファイルを選択して許可アプリを追加
    func addViaOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "対象アプリを選択"
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let bundle = Bundle(url: url),
              let bundleID = bundle.bundleIdentifier else {
            let alert = NSAlert()
            alert.messageText = "アプリの情報を取得できませんでした"
            alert.informativeText = "選択されたアプリからバンドルIDを取得できません。別のアプリを選択してください。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent

        preferencesStore.addAllowedApp(AllowedApp(bundleID: bundleID, name: name))
        apps = preferencesStore.allowedApps
    }
}
