import XCTest
@testable import TermInjector

final class SendHistoryTests: XCTestCase {

    private var history: SendHistory!

    override func setUp() {
        super.setUp()
        history = SendHistory()
    }

    // MARK: - 空の履歴

    func testEmptyHistory_NavigateUp_ReturnsNil() {
        XCTAssertNil(history.navigateUp(current: ""))
    }

    func testEmptyHistory_NavigateDown_ReturnsNil() {
        XCTAssertNil(history.navigateDown())
    }

    // MARK: - 追加と取得

    func testAdd_SingleItem_NavigateUp_ReturnsIt() {
        history.add("hello")
        XCTAssertEqual(history.navigateUp(current: ""), "hello")
    }

    func testAdd_MultipleItems_NavigateUp_ReturnsLatestFirst() {
        history.add("first")
        history.add("second")
        history.add("third")
        XCTAssertEqual(history.navigateUp(current: ""), "third")
        XCTAssertEqual(history.navigateUp(current: "third"), "second")
        XCTAssertEqual(history.navigateUp(current: "second"), "first")
    }

    func testNavigateUp_AtOldestItem_StaysAtOldest() {
        history.add("only")
        XCTAssertEqual(history.navigateUp(current: ""), "only")
        XCTAssertNil(history.navigateUp(current: "only"))
    }

    // MARK: - 下方向ナビゲーション

    func testNavigateDown_AfterUp_ReturnsNewerItem() {
        history.add("first")
        history.add("second")
        _ = history.navigateUp(current: "")
        _ = history.navigateUp(current: "second")
        XCTAssertEqual(history.navigateDown(), "second")
    }

    func testNavigateDown_AtNewest_ReturnsDraft() {
        history.add("first")
        _ = history.navigateUp(current: "my draft")
        XCTAssertEqual(history.navigateDown(), "my draft")
    }

    func testNavigateDown_PastNewest_ReturnsNil() {
        history.add("first")
        _ = history.navigateUp(current: "draft")
        _ = history.navigateDown() // draft に戻る
        XCTAssertNil(history.navigateDown()) // これ以上下には行けない
    }

    // MARK: - ドラフト保持

    func testDraft_PreservedDuringNavigation() {
        history.add("old")
        history.add("new")
        // 現在の入力を保持して上へ
        let up1 = history.navigateUp(current: "my typing")
        XCTAssertEqual(up1, "new")
        let up2 = history.navigateUp(current: "new")
        XCTAssertEqual(up2, "old")
        // 下へ戻る
        let down1 = history.navigateDown()
        XCTAssertEqual(down1, "new")
        let down2 = history.navigateDown()
        XCTAssertEqual(down2, "my typing")
    }

    // MARK: - リセット

    func testReset_ClearsCursorAndDraft() {
        history.add("item")
        _ = history.navigateUp(current: "draft")
        history.reset()
        // リセット後は最新からスタート
        XCTAssertEqual(history.navigateUp(current: ""), "item")
    }

    // MARK: - 上限

    func testMaxItems_OldestDropped() {
        for i in 0..<60 {
            history.add("item\(i)")
        }
        // 最新50件のみ保持
        XCTAssertEqual(history.itemCount, 50)
        // 最も古い保持アイテムは item10
        var lastItem: String?
        for _ in 0..<50 {
            if let item = history.navigateUp(current: lastItem ?? "") {
                lastItem = item
            }
        }
        XCTAssertEqual(lastItem, "item10")
    }

    // MARK: - 追加時のリセット

    func testAdd_ResetsNavigation() {
        history.add("old")
        _ = history.navigateUp(current: "")
        history.add("new")
        // 新しいアイテム追加でカーソルリセット
        XCTAssertEqual(history.navigateUp(current: ""), "new")
    }

    // MARK: - 重複

    func testAdd_DuplicateConsecutive_StillAdded() {
        history.add("same")
        history.add("same")
        XCTAssertEqual(history.itemCount, 2)
    }

    // MARK: - 空テキスト

    func testAdd_EmptyString_NotAdded() {
        history.add("")
        XCTAssertEqual(history.itemCount, 0)
    }

    func testAdd_WhitespaceOnly_NotAdded() {
        history.add("   \n  ")
        XCTAssertEqual(history.itemCount, 0)
    }
}
