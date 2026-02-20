import Cocoa
import SwiftUI

final class PreferencesWindowController: NSWindowController {

    private static var shared: PreferencesWindowController?
    private var closeObserver: NSObjectProtocol?

    static func show() {
        if let existing = shared {
            existing.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "TermInjector 設定"
        window.styleMask = [.titled, .closable]
        window.center()
        window.setFrameAutosaveName("TermInjectorPreferences")

        let controller = PreferencesWindowController(window: window)
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        // ウィンドウが閉じられたときにsharedをクリア
        controller.closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            if let observer = PreferencesWindowController.shared?.closeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            PreferencesWindowController.shared = nil
        }

        shared = controller
    }
}
