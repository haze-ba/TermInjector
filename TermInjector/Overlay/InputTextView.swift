import Cocoa
import UniformTypeIdentifiers

protocol InputTextViewDelegate: AnyObject {
    func inputTextViewDidRequestSend(_ textView: InputTextView, text: String)
    func inputTextViewDidRequestClose(_ textView: InputTextView)
}

final class InputTextView: NSTextView {

    weak var inputDelegate: InputTextViewDelegate?

    /// 現在の設定（PreferencesStoreから同期）
    var keyPreferences = KeyHandlingLogic.Preferences()

    /// 画像添付のパスマップ（Phase 6で使用）
    var imagePathMap: [NSTextAttachment: String] = [:]

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isRichText = false
        allowsUndo = true
        isAutomaticQuoteSubstitutionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticTextReplacementEnabled = false
        font = NSFont.systemFont(ofSize: 14)
        textContainerInset = NSSize(width: 8, height: 8)

        // ドラッグ&ドロップの登録
        registerForDraggedTypes([.fileURL, .png, .tiff])
    }

    var currentText: String {
        return string
    }

    func clearText() {
        // 一時画像ファイルを削除
        if !imagePathMap.isEmpty {
            ImageAttachmentHandler.cleanupImages(Array(imagePathMap.values))
            imagePathMap.removeAll()
        }
        string = ""
        // プレーンテキストモードに戻す
        isRichText = false
    }

    // MARK: - ペースト（画像対応）

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general

        // クリップボードに画像がある場合、画像として処理
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            // テキストも同時にある場合はテキストを優先（通常のペースト）
            if pasteboard.string(forType: .string) != nil {
                super.paste(sender)
                return
            }
            _ = handleImageDrop(image)
            return
        }

        super.paste(sender)
    }

    // MARK: - キーハンドリング（IMEガード）

    override func keyDown(with event: NSEvent) {
        let modifiers = convertModifiers(event.modifierFlags)
        let keyEvent = KeyHandlingLogic.KeyEvent(
            keyCode: event.keyCode,
            modifiers: modifiers,
            hasMarkedText: hasMarkedText()
        )

        let action = KeyHandlingLogic.determineAction(event: keyEvent, preferences: keyPreferences)

        switch action {
        case .send:
            let text = resolveTextForSending()
            inputDelegate?.inputTextViewDidRequestSend(self, text: text)

        case .newline:
            insertNewline(nil)

        case .close:
            inputDelegate?.inputTextViewDidRequestClose(self)

        case .passToIME:
            super.keyDown(with: event)

        case .passToSuper:
            super.keyDown(with: event)
        }
    }

    /// 送信用テキストを生成（画像添付をパスに変換）
    func resolveTextForSending() -> String {
        if imagePathMap.isEmpty {
            return currentText
        }
        return ImageAttachmentHandler.resolveAttachments(
            attributedString(),
            pathMap: imagePathMap
        )
    }

    // MARK: - ドラッグ&ドロップ

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        if pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) {
            return .copy
        }
        // 画像データのドロップ
        if pasteboard.types?.contains(.png) == true || pasteboard.types?.contains(.tiff) == true {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // 画像データのドロップ（Phase 6）
        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData) {
            return handleImageDrop(image)
        }

        // ファイルURLのドロップ
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {

            // 画像ファイルかチェック
            let imageExtensions = Set(["png", "jpg", "jpeg", "gif", "bmp", "tiff", "webp", "heic"])
            let imageURLs = urls.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
            let nonImageURLs = urls.filter { !imageExtensions.contains($0.pathExtension.lowercased()) }

            // 画像ファイルはPhase 6のハンドラーで処理
            for imageURL in imageURLs {
                if let image = NSImage(contentsOf: imageURL) {
                    _ = handleImageDrop(image)
                }
            }

            // 非画像ファイルはパスを挿入
            if !nonImageURLs.isEmpty {
                let paths = FileDropHandler.processDroppedURLs(nonImageURLs)
                let formatted = FileDropHandler.formatPaths(paths)
                insertText(formatted, replacementRange: selectedRange())
            }

            return true
        }

        return super.performDragOperation(sender)
    }

    /// 画像ドロップの処理（Phase 6で完全実装）
    private func handleImageDrop(_ image: NSImage) -> Bool {
        guard let result = ImageAttachmentHandler.processImage(image) else { return false }

        // リッチテキストモードに切り替え（画像表示のため）
        isRichText = true

        let attachment = result.attachment
        imagePathMap[attachment] = result.filePath

        let attachmentString = NSAttributedString(attachment: attachment)
        textStorage?.insert(attachmentString, at: selectedRange().location)

        return true
    }

    private func convertModifiers(_ flags: NSEvent.ModifierFlags) -> KeyHandlingLogic.KeyEvent.Modifiers {
        var modifiers: KeyHandlingLogic.KeyEvent.Modifiers = []
        if flags.contains(.shift) { modifiers.insert(.shift) }
        if flags.contains(.command) { modifiers.insert(.command) }
        if flags.contains(.option) { modifiers.insert(.option) }
        if flags.contains(.control) { modifiers.insert(.control) }
        return modifiers
    }
}
