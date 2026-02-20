import Foundation

enum Constants {
    static let terminalBundleID = "com.apple.Terminal"
    static let appName = "TermInjector"
    static let imageStorageDirectory = ".terminjector/images"

    enum Defaults {
        static let overlayWidth: CGFloat = 480
        static let overlayHeight: CGFloat = 200
        static let injectionPasteDelay: UInt64 = 100_000_000   // 100ms
        static let injectionEnterDelay: UInt64 = 300_000_000  // 300ms
        static let injectionRestoreDelay: UInt64 = 300_000_000 // 300ms
    }
}
