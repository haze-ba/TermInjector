import Cocoa

final class StatusBarController {

    private let statusItem: NSStatusItem
    private let onToggleOverlay: () -> Void
    private let onOpenPreferences: () -> Void

    init(onToggleOverlay: @escaping () -> Void, onOpenPreferences: @escaping () -> Void) {
        self.onToggleOverlay = onToggleOverlay
        self.onOpenPreferences = onOpenPreferences
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        setupButton()
        setupMenu()
    }

    private func setupButton() {
        if let button = statusItem.button {
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
                button.image = image
            } else if let image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: Constants.appName) {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "TI"
            }
            button.toolTip = Constants.appName
        }
    }

    private func setupMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "入力ウィンドウを表示", action: #selector(toggleOverlayAction), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let preferencesItem = NSMenuItem(title: "設定...", action: #selector(openPreferencesAction), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleOverlayAction() {
        onToggleOverlay()
    }

    @objc private func openPreferencesAction() {
        onOpenPreferences()
    }
}
