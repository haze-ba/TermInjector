import Foundation

/// テキスト送信履歴を管理するクラス
final class SendHistory {

    private var items: [String] = []
    /// -1 = 現在の入力（履歴モードではない）
    private var cursor: Int = -1
    /// 履歴ナビゲーション開始前の入力テキスト
    private var currentDraft: String = ""
    private let maxItems = 50

    /// 履歴に保存されているアイテム数
    var itemCount: Int { items.count }

    /// 履歴ナビゲーション中かどうか
    var isNavigating: Bool { cursor >= 0 }

    /// 送信テキストを履歴に追加する
    /// - Parameter text: 追加するテキスト（空文字列やホワイトスペースのみは無視）
    func add(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.append(text)
        if items.count > maxItems {
            items.removeFirst(items.count - maxItems)
        }
        cursor = -1
        currentDraft = ""
    }

    /// 古い履歴方向へ移動する
    /// - Parameter current: 現在のテキスト入力内容（初回呼び出し時にドラフトとして保存）
    /// - Returns: 履歴テキスト。これ以上古い履歴がなければnil
    func navigateUp(current: String) -> String? {
        guard !items.isEmpty else { return nil }

        if cursor == -1 {
            // 初めての上方向ナビゲーション：ドラフトを保存
            currentDraft = current
            cursor = items.count - 1
            return items[cursor]
        }

        // 既にナビゲーション中：さらに古い方向へ
        if cursor > 0 {
            cursor -= 1
            return items[cursor]
        }

        // 最も古いアイテムに到達
        return nil
    }

    /// 新しい履歴方向へ移動する
    /// - Returns: 履歴テキスト、またはドラフトに戻った場合はドラフト。移動できなければnil
    func navigateDown() -> String? {
        guard cursor >= 0 else { return nil }

        if cursor < items.count - 1 {
            cursor += 1
            return items[cursor]
        }

        // 最新アイテムの次 → ドラフトに戻る
        cursor = -1
        return currentDraft
    }

    /// ナビゲーション状態をリセットする（カーソルとドラフトをクリア）
    func reset() {
        cursor = -1
        currentDraft = ""
    }
}
