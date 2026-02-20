import XCTest
@testable import TermInjector

final class ClipboardManagerTests: XCTestCase {

    private var manager: ClipboardManager!
    private var mockPasteboard: MockPasteboard!

    override func setUp() {
        super.setUp()
        mockPasteboard = MockPasteboard()
        manager = ClipboardManager(pasteboard: mockPasteboard)
    }

    // MARK: - save

    func testSave_EmptyPasteboard_ReturnsEmptySnapshot() {
        mockPasteboard.mockItems = nil
        let snapshot = manager.save()
        XCTAssertTrue(snapshot.items.isEmpty)
    }

    func testSave_WithTextItem_PreservesData() {
        let item = MockPasteboardItem()
        item.mockTypes = [.string]
        item.mockData = [.string: "Hello".data(using: .utf8)!]
        mockPasteboard.mockItems = [item]
        mockPasteboard.mockChangeCount = 42

        let snapshot = manager.save()

        XCTAssertEqual(snapshot.items.count, 1)
        XCTAssertEqual(snapshot.changeCount, 42)
        XCTAssertEqual(snapshot.items[0].types, [.string])
        XCTAssertNotNil(snapshot.items[0].dataByType[.string])
    }

    func testSave_WithMultipleTypes_PreservesAll() {
        let item = MockPasteboardItem()
        item.mockTypes = [.string, .rtf]
        item.mockData = [
            .string: "Hello".data(using: .utf8)!,
            .rtf: "RTF data".data(using: .utf8)!,
        ]
        mockPasteboard.mockItems = [item]

        let snapshot = manager.save()

        XCTAssertEqual(snapshot.items[0].dataByType.count, 2)
    }

    // MARK: - setText

    func testSetText_ClearsAndSetsString() {
        let result = manager.setText("Test")

        XCTAssertTrue(result)
        XCTAssertTrue(mockPasteboard.clearContentsCalled)
        XCTAssertEqual(mockPasteboard.lastSetString, "Test")
    }

    // MARK: - restore

    func testRestore_EmptySnapshot_Succeeds() {
        let snapshot = ClipboardSnapshot(items: [], changeCount: 0)
        let result = manager.restore(snapshot, force: true)

        XCTAssertTrue(result)
        XCTAssertTrue(mockPasteboard.clearContentsCalled)
    }

    func testRestore_WithItems_WritesObjects() {
        let item = ClipboardSnapshot.Item(
            types: [.string],
            dataByType: [.string: "Restored".data(using: .utf8)!]
        )
        let snapshot = ClipboardSnapshot(items: [item], changeCount: 0)

        let result = manager.restore(snapshot, force: true)

        XCTAssertTrue(result)
        XCTAssertTrue(mockPasteboard.writeObjectsCalled)
    }

    // MARK: - restore changeCount ガード

    func testRestore_ChangeCountMatch_Restores() {
        // save時のchangeCount=10、setText後に+1で11のはず
        mockPasteboard.mockChangeCount = 11
        let snapshot = ClipboardSnapshot(items: [], changeCount: 10)

        let result = manager.restore(snapshot, force: false)

        XCTAssertTrue(result, "changeCountが一致すれば復元される")
        XCTAssertTrue(mockPasteboard.clearContentsCalled)
    }

    func testRestore_ChangeCountMismatch_SkipsRestore() {
        // save時のchangeCount=10だが、現在は15（他アプリが書き換えた）
        mockPasteboard.mockChangeCount = 15
        let snapshot = ClipboardSnapshot(items: [
            ClipboardSnapshot.Item(types: [.string], dataByType: [.string: Data()])
        ], changeCount: 10)

        let result = manager.restore(snapshot, force: false)

        XCTAssertFalse(result, "changeCountが不一致なら復元をスキップ")
        XCTAssertFalse(mockPasteboard.clearContentsCalled, "スキップ時はクリアしない")
        XCTAssertFalse(mockPasteboard.writeObjectsCalled, "スキップ時は書き込みしない")
    }

    func testRestore_ChangeCountMismatch_ForceTrue_Restores() {
        // changeCount不一致でもforce=trueなら復元する
        mockPasteboard.mockChangeCount = 15
        let snapshot = ClipboardSnapshot(items: [], changeCount: 10)

        let result = manager.restore(snapshot, force: true)

        XCTAssertTrue(result, "force=trueならchangeCount不一致でも復元される")
        XCTAssertTrue(mockPasteboard.clearContentsCalled)
    }
}

// MARK: - Mock

private final class MockPasteboardItem {
    var mockTypes: [NSPasteboard.PasteboardType] = []
    var mockData: [NSPasteboard.PasteboardType: Data] = [:]
}

private final class MockPasteboard: PasteboardProtocol {
    var mockChangeCount: Int = 0
    var mockItems: [MockPasteboardItem]?
    var clearContentsCalled = false
    var lastSetString: String?
    var writeObjectsCalled = false

    var changeCount: Int { mockChangeCount }

    var pasteboardItems: [NSPasteboardItem]? {
        guard let items = mockItems else { return nil }
        return items.map { mockItem in
            let pbItem = NSPasteboardItem()
            for (type, data) in mockItem.mockData {
                pbItem.setData(data, forType: type)
            }
            return pbItem
        }
    }

    func clearContents() -> Int {
        clearContentsCalled = true
        mockChangeCount += 1
        return mockChangeCount
    }

    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool {
        lastSetString = string
        mockChangeCount += 1
        return true
    }

    func writeObjects(_ objects: [NSPasteboardWriting]) -> Bool {
        writeObjectsCalled = true
        return true
    }
}
