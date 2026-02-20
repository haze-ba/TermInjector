import Cocoa
import ApplicationServices

/// アクセシビリティ権限のチェックと誘導
enum AccessibilityChecker {

    /// アクセシビリティ権限が許可されているか確認する
    static func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }

    /// アクセシビリティ権限を要求する（システム環境設定を開く）
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// 権限がなければ確認ダイアログを表示し、ユーザーに許可を促す
    /// - Returns: 権限が許可されているかどうか
    @discardableResult
    static func ensureAccessibility() -> Bool {
        if isAccessibilityEnabled() {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要です"
        alert.informativeText = "TermInjectorがTerminal.appにテキストを送信するには、アクセシビリティ権限が必要です。\n\n「システム設定」→「プライバシーとセキュリティ」→「アクセシビリティ」でTermInjectorを許可してください。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "設定を開く")
        alert.addButton(withTitle: "キャンセル")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            requestAccessibility()
        }

        return false
    }
}
