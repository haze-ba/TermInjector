import Cocoa

/// 画像添付の処理結果
struct ImageProcessResult {
    let attachment: NSTextAttachment
    let filePath: String
}

/// 画像添付の処理（一時ファイル保存、サムネイル生成、パス変換）
enum ImageAttachmentHandler {

    /// 画像の保存先ディレクトリ
    static var imageStorageURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(Constants.imageStorageDirectory)
    }

    /// 画像を処理する（一時ファイル保存 + サムネイル + NSTextAttachment）
    /// - Parameter image: 処理するNSImage
    /// - Returns: 処理結果（attachment + ファイルパス）、失敗時はnil
    static func processImage(_ image: NSImage) -> ImageProcessResult? {
        // 保存ディレクトリの準備
        let storageURL = imageStorageURL
        do {
            try FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
        } catch {
            NSLog("[TermInjector] 画像保存ディレクトリの作成に失敗: \(error)")
            return nil
        }

        // ファイル名生成
        let filename = generateFilename()
        let fileURL = storageURL.appendingPathComponent(filename)

        // PNG形式で保存
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            NSLog("[TermInjector] 画像データの変換に失敗")
            return nil
        }

        do {
            try pngData.write(to: fileURL)
        } catch {
            NSLog("[TermInjector] 画像ファイルの保存に失敗: \(error)")
            return nil
        }

        // サムネイル生成
        let thumbnail = createThumbnail(image, maxSize: 120)

        // NSTextAttachment作成
        let attachment = NSTextAttachment()
        let cell = NSTextAttachmentCell(imageCell: thumbnail)
        attachment.attachmentCell = cell

        return ImageProcessResult(attachment: attachment, filePath: fileURL.path)
    }

    /// NSAttributedString内の画像添付をファイルパスに変換する
    /// - Parameters:
    ///   - attributedString: 変換元のNSAttributedString
    ///   - pathMap: NSTextAttachment→ファイルパスのマップ
    /// - Returns: パス変換済みのテキスト
    static func resolveAttachments(_ attributedString: NSAttributedString, pathMap: [NSTextAttachment: String]) -> String {
        var result = ""
        let fullRange = NSRange(location: 0, length: attributedString.length)

        attributedString.enumerateAttributes(in: fullRange, options: []) { attrs, range, _ in
            if let attachment = attrs[.attachment] as? NSTextAttachment,
               let path = pathMap[attachment] {
                result += path
            } else {
                let substring = (attributedString.string as NSString).substring(with: range)
                // NSTextAttachmentの特殊文字（\u{FFFC}）を除外
                let cleaned = substring.replacingOccurrences(of: "\u{FFFC}", with: "")
                result += cleaned
            }
        }

        return result
    }

    /// ファイル名を生成する（yyyyMMdd_HHmmss_UUID8桁.png）
    static func generateFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = formatter.string(from: Date())
        let uuid = UUID().uuidString.prefix(8)
        return "\(dateString)_\(uuid).png"
    }

    /// 指定されたファイルパスの一時画像を削除する
    /// - Parameter paths: 削除するファイルパスの配列
    static func cleanupImages(_ paths: [String]) {
        let fm = FileManager.default
        let storageDir = imageStorageURL.standardizedFileURL.resolvingSymlinksInPath()
        for path in paths {
            // 安全チェック: imageStorageURL直下のファイルのみ削除する
            let fileURL = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
            guard fileURL.deletingLastPathComponent() == storageDir else { continue }
            do {
                try fm.removeItem(at: fileURL)
            } catch {
                NSLog("[TermInjector] 一時画像の削除に失敗: \(path) - \(error)")
            }
        }
    }

    /// 保存期限を過ぎた古い一時画像を一括削除する
    /// - Parameter olderThan: この日付より前に作成されたファイルを削除（デフォルト: 24時間前）
    static func cleanupOldImages(olderThan date: Date = Date(timeIntervalSinceNow: -86400)) {
        let fm = FileManager.default
        let storageURL = imageStorageURL

        guard let files = try? fm.contentsOfDirectory(at: storageURL, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }

        for fileURL in files {
            guard fileURL.pathExtension == "png" else { continue }
            guard let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attrs[.creationDate] as? Date else { continue }
            if creationDate < date {
                try? fm.removeItem(at: fileURL)
            }
        }
    }

    /// サムネイル画像を生成する
    /// - Parameters:
    ///   - image: 元画像
    ///   - maxSize: 最大辺長（ピクセル）
    /// - Returns: リサイズされた画像
    static func createThumbnail(_ image: NSImage, maxSize: CGFloat) -> NSImage {
        let originalSize = image.size
        guard originalSize.width > 0 && originalSize.height > 0 else { return image }

        // 最大サイズ以下ならそのまま返す
        if originalSize.width <= maxSize && originalSize.height <= maxSize {
            return image
        }

        let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)
        let newSize = NSSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )

        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()

        return thumbnail
    }
}
