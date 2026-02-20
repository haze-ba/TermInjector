import XCTest
@testable import TermInjector

final class ImageAttachmentHandlerTests: XCTestCase {

    // MARK: - generateFilename

    func testGenerateFilename_Format() {
        let filename = ImageAttachmentHandler.generateFilename()

        // yyyyMMdd_HHmmss_UUID8桁.png の形式
        XCTAssertTrue(filename.hasSuffix(".png"))

        let nameWithoutExtension = String(filename.dropLast(4)) // .png を除去
        let parts = nameWithoutExtension.split(separator: "_")
        XCTAssertEqual(parts.count, 3, "ファイル名は date_time_uuid の3パート")

        // 日付部分: 8桁
        XCTAssertEqual(parts[0].count, 8)
        // 時刻部分: 6桁
        XCTAssertEqual(parts[1].count, 6)
        // UUID部分: 8桁
        XCTAssertEqual(parts[2].count, 8)
    }

    func testGenerateFilename_Unique() {
        let name1 = ImageAttachmentHandler.generateFilename()
        let name2 = ImageAttachmentHandler.generateFilename()
        XCTAssertNotEqual(name1, name2, "連続生成で異なるファイル名になる")
    }

    // MARK: - resolveAttachments

    func testResolveAttachments_PlainText() {
        let attrString = NSAttributedString(string: "Hello World")
        let result = ImageAttachmentHandler.resolveAttachments(attrString, pathMap: [:])
        XCTAssertEqual(result, "Hello World")
    }

    func testResolveAttachments_WithAttachment() {
        let attachment = NSTextAttachment()
        let attachmentString = NSMutableAttributedString(attachment: attachment)

        let prefix = NSAttributedString(string: "前文 ")
        let suffix = NSAttributedString(string: " 後文")

        let combined = NSMutableAttributedString()
        combined.append(prefix)
        combined.append(attachmentString)
        combined.append(suffix)

        let pathMap: [NSTextAttachment: String] = [attachment: "/tmp/test.png"]
        let result = ImageAttachmentHandler.resolveAttachments(combined, pathMap: pathMap)

        XCTAssertEqual(result, "前文 /tmp/test.png 後文")
    }

    func testResolveAttachments_MultipleAttachments() {
        let attachment1 = NSTextAttachment()
        let attachment2 = NSTextAttachment()

        let combined = NSMutableAttributedString()
        combined.append(NSAttributedString(attachment: attachment1))
        combined.append(NSAttributedString(string: " "))
        combined.append(NSAttributedString(attachment: attachment2))

        let pathMap: [NSTextAttachment: String] = [
            attachment1: "/tmp/a.png",
            attachment2: "/tmp/b.png",
        ]
        let result = ImageAttachmentHandler.resolveAttachments(combined, pathMap: pathMap)

        XCTAssertEqual(result, "/tmp/a.png /tmp/b.png")
    }

    // MARK: - imageStorageURL

    func testImageStorageURL_ContainsTerminjector() {
        let url = ImageAttachmentHandler.imageStorageURL
        XCTAssertTrue(url.path.contains(".terminjector/images"))
    }

    // MARK: - cleanupImages

    func testCleanupImages_DeletesSpecifiedFiles() {
        let fm = FileManager.default
        let storageURL = ImageAttachmentHandler.imageStorageURL
        try? fm.createDirectory(at: storageURL, withIntermediateDirectories: true)

        // テスト用の一時ファイルを作成
        let testFile = storageURL.appendingPathComponent("test_cleanup.png")
        fm.createFile(atPath: testFile.path, contents: Data([0x00]))
        XCTAssertTrue(fm.fileExists(atPath: testFile.path))

        // 削除
        ImageAttachmentHandler.cleanupImages([testFile.path])

        XCTAssertFalse(fm.fileExists(atPath: testFile.path))
    }

    func testCleanupImages_IgnoresPathsOutsideStorageDir() {
        let fm = FileManager.default
        let tempFile = NSTemporaryDirectory() + "terminjector_test_safety.txt"
        fm.createFile(atPath: tempFile, contents: Data([0x00]))
        XCTAssertTrue(fm.fileExists(atPath: tempFile))

        // storageURL配下でないパスは削除されない
        ImageAttachmentHandler.cleanupImages([tempFile])

        XCTAssertTrue(fm.fileExists(atPath: tempFile), "storageURL外のファイルは削除されない")
        try? fm.removeItem(atPath: tempFile)
    }

    func testCleanupOldImages_DeletesOldFiles() {
        let fm = FileManager.default
        let storageURL = ImageAttachmentHandler.imageStorageURL
        try? fm.createDirectory(at: storageURL, withIntermediateDirectories: true)

        // テスト用ファイルを作成
        let oldFile = storageURL.appendingPathComponent("old_test.png")
        fm.createFile(atPath: oldFile.path, contents: Data([0x00]))

        // 作成日を2日前に設定
        let twoDaysAgo = Date(timeIntervalSinceNow: -172800)
        try? fm.setAttributes([.creationDate: twoDaysAgo], ofItemAtPath: oldFile.path)

        // 24時間以上前のファイルを削除
        ImageAttachmentHandler.cleanupOldImages()

        XCTAssertFalse(fm.fileExists(atPath: oldFile.path), "古いファイルが削除される")
    }

    func testCleanupOldImages_KeepsRecentFiles() {
        let fm = FileManager.default
        let storageURL = ImageAttachmentHandler.imageStorageURL
        try? fm.createDirectory(at: storageURL, withIntermediateDirectories: true)

        // テスト用ファイルを作成（新しいファイル）
        let recentFile = storageURL.appendingPathComponent("recent_test.png")
        fm.createFile(atPath: recentFile.path, contents: Data([0x00]))

        // 24時間以上前のファイルを削除
        ImageAttachmentHandler.cleanupOldImages()

        XCTAssertTrue(fm.fileExists(atPath: recentFile.path), "新しいファイルは削除されない")
        try? fm.removeItem(at: recentFile)
    }
}
