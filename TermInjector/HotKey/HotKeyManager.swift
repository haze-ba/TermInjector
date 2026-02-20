import Cocoa
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleOverlay = Self("toggleOverlay", default: .init(.space, modifiers: [.command, .option]))
}

final class HotKeyManager {

    private let onToggle: () -> Void

    init(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        KeyboardShortcuts.onKeyUp(for: .toggleOverlay) { [weak self] in
            self?.onToggle()
        }
    }
}
