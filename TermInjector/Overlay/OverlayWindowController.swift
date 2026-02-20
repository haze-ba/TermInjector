import Cocoa

final class OverlayWindowController: NSWindowController {

    private let overlayViewController = OverlayViewController()
    private let terminalInjector = TerminalInjector()
    private let preferencesStore = PreferencesStore()

    /// オーバーレイ表示直前のフォアグラウンドアプリ
    private(set) var previousFrontmostApp: NSRunningApplication?

    /// 送信中フラグ（同時送信防止）
    private var isSending = false

    convenience init() {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.Defaults.overlayWidth,
                height: Constants.Defaults.overlayHeight
            ),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = Constants.appName
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false // IMEのためキーウィンドウ化を許可
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = false
        panel.titleVisibility = .visible
        panel.minSize = NSSize(width: 300, height: 120)

        // 前回の位置を復元、なければ画面中央
        panel.center()
        panel.setFrameAutosaveName("TermInjectorOverlay")

        self.init(window: panel)

        panel.contentViewController = overlayViewController

        overlayViewController.onSend = { [weak self] text in
            self?.handleSend(text)
        }
    }

    func toggle() {
        guard let panel = window else { return }

        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let panel = window else { return }

        // 表示直前のフォアグラウンドアプリを記憶
        previousFrontmostApp = NSWorkspace.shared.frontmostApplication

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        overlayViewController.focusInput()
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func handleSend(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 同時送信を防止
        guard !isSending else { return }
        isSending = true

        let shouldClose = preferencesStore.closeAfterSend
        let sendEnter = !preferencesStore.pasteOnly
        let previousApp = previousFrontmostApp

        // テキストを保持してから送信（失敗時に復元するため）
        let savedText = text

        Task {
            let result = await terminalInjector.inject(
                text: savedText,
                sendEnter: sendEnter,
                previousApp: previousApp
            )

            await MainActor.run {
                self.isSending = false

                switch result {
                case .success:
                    NSLog("[TermInjector] テキスト注入成功")
                    // 成功後にクリア・クローズ
                    self.overlayViewController.clearInput()
                    if shouldClose {
                        self.hide()
                    }

                case .noAccessibility:
                    NSLog("[TermInjector] アクセシビリティ権限がありません")
                    // テキストはクリアしない（ユーザーが再送信できるように）

                case .terminalNotRunning:
                    self.showError("Terminal.appが起動していません。Terminal.appを起動してから再度お試しください。")

                case .injectionFailed(let message):
                    self.showError("テキスト注入に失敗しました: \(message)")

                case .safetyCheckFailed(let message):
                    self.showError(message)
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "送信エラー"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
