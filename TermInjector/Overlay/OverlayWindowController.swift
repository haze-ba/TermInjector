import Cocoa

final class OverlayWindowController: NSWindowController {

    private let overlayViewController = OverlayViewController()
    private let terminalInjector = TerminalInjector()
    private let preferencesStore = PreferencesStore()
    private let sendHistory = SendHistory()

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
        overlayViewController.setSendHistory(sendHistory)

        overlayViewController.onSend = { [weak self] text in
            self?.handleSend(text)
        }
    }

    func toggle() {
        guard let panel = window else { return }

        if panel.isVisible {
            if panel.isKeyWindow {
                hide()  // フォーカス中 → 閉じる
            } else {
                refocus()  // フォーカス外 → 再フォーカス
            }
        } else {
            show()
        }
    }

    func show() {
        guard let panel = window else { return }

        // 非表示→表示の遷移時のみ、直前のフォアグラウンドアプリを記憶
        if !panel.isVisible {
            let frontmost = NSWorkspace.shared.frontmostApplication
            // hide()直後のレース条件で自分自身が返る場合は記録を更新しない
            if frontmost?.bundleIdentifier != Bundle.main.bundleIdentifier {
                previousFrontmostApp = frontmost
            }
        }

        // ターミナルウィンドウ追従
        if preferencesStore.followTerminalWindow, let targetFrame = getTargetWindowFrame() {
            positionOverlay(relativeTo: targetFrame, position: preferencesStore.overlayPosition)
        }

        // .accessoryアプリでもアクティブ状態に関係なくキーウィンドウ化するためorderFrontRegardlessを使用
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
        overlayViewController.focusInput()
    }

    func hide() {
        window?.orderOut(nil)
    }

    /// パネルが表示中だがフォーカスを失っている場合に再フォーカスする
    /// previousFrontmostApp は更新しない（元のターミナルに送信するため）
    private func refocus() {
        guard let panel = window, panel.isVisible else { return }
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
        overlayViewController.focusInput()
    }

    private func handleSend(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 同時送信を防止
        guard !isSending else { return }
        isSending = true

        let shouldClose = preferencesStore.closeAfterSend
        let previousApp = previousFrontmostApp

        // テキストを保持してから送信（失敗時に復元するため）
        let savedText = text

        // 送信前にパネルを非表示にする（CGEventがTerminalに確実に届くようにする）
        hide()

        Task {
            let result = await terminalInjector.inject(
                text: savedText,
                previousApp: previousApp
            )

            await MainActor.run {
                self.isSending = false

                switch result {
                case .success:
                    NSLog("[TermInjector] テキスト注入成功")
                    self.sendHistory.add(savedText)
                    self.sendHistory.reset()
                    if !self.preferencesStore.retainTextAfterSend {
                        self.overlayViewController.clearInput()
                    }
                    if !shouldClose {
                        // 送信後もウィンドウを開きたい場合は再表示
                        self.show()
                    }

                case .noAccessibility:
                    NSLog("[TermInjector] アクセシビリティ権限がありません")
                    // 失敗時はパネルを再表示し、送信先アプリの記憶を復元
                    self.show()
                    self.previousFrontmostApp = previousApp

                case .targetAppNotRunning:
                    self.show()
                    self.previousFrontmostApp = previousApp
                    self.showError("送信先のアプリが起動していません。対象アプリを起動してから再度お試しください。")

                case .injectionFailed(let message):
                    self.show()
                    self.previousFrontmostApp = previousApp
                    self.showError("テキスト注入に失敗しました: \(message)")

                case .safetyCheckFailed(let message):
                    self.show()
                    self.previousFrontmostApp = previousApp
                    self.showError(message)
                }
            }
        }
    }

    // MARK: - ウィンドウ追従

    /// ターゲットアプリのウィンドウフレームを取得する
    private func getTargetWindowFrame() -> CGRect? {
        guard let pid = previousFrontmostApp?.processIdentifier else { return nil }
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        for windowInfo in windowList {
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == pid,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] else {
                continue
            }
            // CGWindowListのboundsはスクリーン座標系（Y軸が上から下）
            let x = boundsDict["X"] ?? 0
            let y = boundsDict["Y"] ?? 0
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0
            return CGRect(x: x, y: y, width: width, height: height)
        }
        return nil
    }

    /// オーバーレイをターゲットウィンドウに対して配置する
    private func positionOverlay(relativeTo targetFrame: CGRect, position: String) {
        guard let panel = window else { return }
        let overlaySize = panel.frame.size
        // CGWindowListのY座標はプライマリスクリーンの左上が原点（Y軸下向き）
        // NSWindowのY座標はプライマリスクリーンの左下が原点（Y軸上向き）
        guard let primaryScreenHeight = NSScreen.screens.first?.frame.height else { return }

        // CGWindowListのY座標（上から下）をNSWindow座標（下から上）に変換
        let targetNSY = primaryScreenHeight - targetFrame.origin.y - targetFrame.height

        var origin: NSPoint
        switch position {
        case "top":
            origin = NSPoint(
                x: targetFrame.midX - overlaySize.width / 2,
                y: targetNSY + targetFrame.height
            )
        case "left":
            origin = NSPoint(
                x: targetFrame.origin.x - overlaySize.width,
                y: targetNSY + (targetFrame.height - overlaySize.height) / 2
            )
        case "right":
            origin = NSPoint(
                x: targetFrame.origin.x + targetFrame.width,
                y: targetNSY + (targetFrame.height - overlaySize.height) / 2
            )
        default: // "bottom"
            origin = NSPoint(
                x: targetFrame.midX - overlaySize.width / 2,
                y: targetNSY - overlaySize.height
            )
        }

        panel.setFrameOrigin(origin)
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
