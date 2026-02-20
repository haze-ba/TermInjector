import Cocoa

/// クリップボード内容のスナップショット
struct ClipboardSnapshot {
    struct Item {
        let types: [NSPasteboard.PasteboardType]
        let dataByType: [NSPasteboard.PasteboardType: Data]
    }
    let items: [Item]
    let changeCount: Int
}

/// NSPasteboardへのアクセスを抽象化するプロトコル（テスト用）
protocol PasteboardProtocol {
    var changeCount: Int { get }
    var pasteboardItems: [NSPasteboardItem]? { get }
    func clearContents() -> Int
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool
    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool
}

extension NSPasteboard: PasteboardProtocol {}

/// クリップボード内容の退避と復元を管理する
final class ClipboardManager {

    private let pasteboard: PasteboardProtocol

    init(pasteboard: PasteboardProtocol = NSPasteboard.general) {
        self.pasteboard = pasteboard
    }

    /// 現在のクリップボード内容を保存する
    func save() -> ClipboardSnapshot {
        var items: [ClipboardSnapshot.Item] = []

        if let pbItems = pasteboard.pasteboardItems {
            for pbItem in pbItems {
                let types = pbItem.types
                var dataByType: [NSPasteboard.PasteboardType: Data] = [:]
                for type in types {
                    if let data = pbItem.data(forType: type) {
                        dataByType[type] = data
                    }
                }
                items.append(ClipboardSnapshot.Item(types: types, dataByType: dataByType))
            }
        }

        return ClipboardSnapshot(items: items, changeCount: pasteboard.changeCount)
    }

    /// クリップボードにテキストを設定する
    @discardableResult
    func setText(_ text: String) -> Bool {
        _ = pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    /// 保存したスナップショットからクリップボードを復元する
    ///
    /// - Parameter snapshot: 復元するスナップショット
    /// - Parameter force: trueの場合、changeCount変更チェックをスキップ
    /// - Returns: 復元成功ならtrue
    @discardableResult
    func restore(_ snapshot: ClipboardSnapshot, force: Bool = false) -> Bool {
        // 他のアプリがクリップボードを書き換えた場合はスキップ
        if !force && pasteboard.changeCount != snapshot.changeCount + 1 {
            // changeCountは setText で +1 されているはず
            // それ以外の変化があった場合、他アプリによる書き換えの可能性あり
            return false
        }

        _ = pasteboard.clearContents()

        if snapshot.items.isEmpty {
            return true
        }

        var pasteboardItems: [NSPasteboardItem] = []
        for item in snapshot.items {
            let pbItem = NSPasteboardItem()
            for (type, data) in item.dataByType {
                pbItem.setData(data, forType: type)
            }
            pasteboardItems.append(pbItem)
        }

        return pasteboard.writeObjects(pasteboardItems)
    }
}
