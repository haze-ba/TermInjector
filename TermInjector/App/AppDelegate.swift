import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var hotKeyManager: HotKeyManager?
    private let overlayWindowController = OverlayWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 標準編集メニューを構築（Cmd+X/C/V/A/Z をNSTextViewで有効にする）
        setupMainMenu()

        statusBarController = StatusBarController(
            onToggleOverlay: { [weak self] in
                self?.toggleOverlay()
            },
            onOpenPreferences: { [weak self] in
                self?.openPreferences()
            }
        )

        hotKeyManager = HotKeyManager(onToggle: { [weak self] in
            self?.toggleOverlay()
        })

        // 起動時のアクセシビリティ権限チェック
        checkAccessibilityOnLaunch()

        // 起動時に24時間以上前の一時画像を削除
        ImageAttachmentHandler.cleanupOldImages()
    }

    private func checkAccessibilityOnLaunch() {
        if !AccessibilityChecker.isAccessibilityEnabled() {
            // 初回起動時にアクセシビリティ権限を案内
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AccessibilityChecker.ensureAccessibility()
            }
        }
    }

    private func toggleOverlay() {
        overlayWindowController.toggle()
    }

    private func openPreferences() {
        PreferencesWindowController.show()
    }

    /// 標準編集メニューを構築する
    /// .accessoryポリシーのアプリでもCmd+X/C/V/A/ZがNSTextViewで動作するようにする
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // アプリメニュー（必須）
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "TermInjectorについて", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "TermInjectorを終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 編集メニュー
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "編集")
        editMenu.addItem(NSMenuItem(title: "取り消す", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "やり直す", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "カット", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "コピー", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "ペースト", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "すべてを選択", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }
}
