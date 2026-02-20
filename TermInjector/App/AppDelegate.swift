import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var hotKeyManager: HotKeyManager?
    private let overlayWindowController = OverlayWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

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
}
