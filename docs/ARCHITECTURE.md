# Architecture

## 全体構成

```
┌─────────────────────────────────────────────────┐
│              main.swift → AppDelegate              │
│  - main.swift: NSApplication.shared + delegate設定 │
│  - NSApp.setActivationPolicy(.accessory)           │
│  - setupMainMenu(): 標準編集メニュー構築             │
│  - StatusBarController / HotKeyManager 初期化       │
│  - 起動時: アクセシビリティ権限チェック、画像クリーンアップ │
└────────┬──────────────────────┬──────────────────┘
         │                      │
         ▼                      ▼
┌─────────────────┐   ┌─────────────────┐
│ StatusBarController│   │  HotKeyManager   │
│ NSStatusItem      │   │ KeyboardShortcuts │
│ メニュー管理       │   │ Cmd+Opt+Space    │
└────────┬──────────┘   └────────┬─────────┘
         │ onToggleOverlay        │ onToggle
         ▼                        ▼
┌─────────────────────────────────────────────────┐
│            OverlayWindowController                │
│  - NSPanel (.floating level)                      │
│  - toggle(): 3状態制御                             │
│    - フォーカス中 → hide()                          │
│    - 表示中・フォーカス外 → refocus()                │
│    - 非表示 → show()                               │
│  - 送信時: hide() → inject() → 結果に応じて再表示   │
│  - 前面アプリ記憶 (previousApp, 非表示→表示時のみ)   │
│  - 並行送信防止 (isSending flag)                    │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│            OverlayViewController                  │
│  - NSScrollView + InputTextView + フッターラベル   │
│  - PreferencesStore → InputTextView への設定同期   │
└────────┬────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│              InputTextView (NSTextView)           │
│  - IMEガード (hasMarkedText チェック)              │
│  - KeyHandlingLogic で keyDown 判定               │
│  - ファイルドロップ (FileDropHandler)              │
│  - 画像ペースト/ドロップ (ImageAttachmentHandler)  │
│  - imagePathMap: [NSTextAttachment: String]       │
└──────────────────────────────────────────────────┘
```

## 注入シーケンス

```
OverlayWindowController.handleSend()
    │
    ├─ 0. hide() — パネルを非表示化（CGEventがTerminalに確実に届くようにする）
    │
    ▼
TerminalInjector.inject(text:, previousApp:)
    │
    ├─ 1. AccessibilityChecker.ensureAccessibility()
    ├─ 2. TerminalDetector.findTerminalApp()
    ├─ 3. ClipboardManager.save() → ClipboardSnapshot
    ├─ 4. ClipboardManager.setText(text)
    ├─ 5. Terminal.app アクティブ化 (activate, 最大3回リトライ)
    ├─ 6. 待機 50ms → KeySimulator.simulatePaste() (Cmd+V)
    ├─ 7. 待機 100ms → KeySimulator.simulateEnter() (設定による)
    └─ 8. 待機 200ms → ClipboardManager.restore(snapshot)
    │
    ▼
結果ハンドリング
    ├─ 成功 + closeAfterSend=false → show() で再表示
    ├─ 成功 + closeAfterSend=true  → そのまま非表示
    └─ 失敗 → show() + previousFrontmostApp復元 + エラー表示
```

## キー入力の判定フロー

```
keyDown(with: event)
    │
    ├─ Escape → .close
    │
    ├─ hasMarkedText == true (IME変換中)
    │   ├─ Enter/Return → .passToIME (確定操作)
    │   ├─ Cmd+Enter → .passToIME
    │   └─ その他 → .passToSuper
    │
    ├─ hasMarkedText == false (確定済み)
    │   ├─ Shift+Enter → .newline
    │   ├─ Cmd+Enter
    │   │   ├─ cmdEnterForced → .send
    │   │   ├─ cmdEnterSend → .send
    │   │   ├─ pasteOnly && !cmdEnterForced → .newline
    │   │   └─ else → .passToSuper
    │   ├─ Enter
    │   │   ├─ pasteOnly → .newline
    │   │   ├─ enterSend → .send
    │   │   └─ else → .newline
    │   └─ その他 → .passToSuper
```

## クリップボード管理

```
ClipboardSnapshot
├── items: [Item]
│   └── Item
│       ├── types: [NSPasteboard.PasteboardType]
│       └── dataByType: [PasteboardType: Data]
└── changeCount: Int

ClipboardManager
├── save() → ClipboardSnapshot     # 全タイプ・全アイテムを退避
├── setText(String) → Bool          # clearContents + setString
└── restore(snapshot, force) → Bool # changeCountガード付き復元
    └── force=false時: changeCount != snapshot.changeCount + 1 なら復元スキップ
```

## 画像処理フロー

```
画像ペースト/ドロップ
    │
    ▼
ImageAttachmentHandler.processImage(NSImage)
    ├─ ~/.terminjector/images/ にPNG保存
    ├─ サムネイル生成 (最大120x120)
    └─ NSTextAttachment + ファイルパスを返却
        │
        ▼
InputTextView.imagePathMap に記録
    │
    ▼ (送信時)
ImageAttachmentHandler.resolveAttachments(attrString, pathMap)
    └─ NSTextAttachment → ファイルパスに変換した最終テキストを生成

クリーンアップ:
- clearText() 時: cleanupImages() で当該送信の一時画像を削除
- アプリ起動時: cleanupOldImages() で24時間以上前のファイルを一括削除
```

## テスト戦略

外部依存はプロトコルで抽象化し、テスト時はモックに差し替える。

| プロトコル | 本番実装 | テスト用モック |
|-----------|---------|-------------|
| `PasteboardProtocol` | `NSPasteboard` | `MockPasteboard` |
| `TerminalDetectorProtocol` | `TerminalDetector` | `MockTerminalDetector` |

純粋関数として分離されたロジック（テスト容易）:
- `KeyHandlingLogic.determineAction()` — キー判定
- `FileDropHandler.escapePath()` — シェルエスケープ
- `ImageAttachmentHandler.generateFilename()` — ファイル名生成
- `ImageAttachmentHandler.resolveAttachments()` — パス解決

## 依存ライブラリ

| ライブラリ | 用途 | バージョン |
|-----------|------|-----------|
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | グローバルホットキー登録・設定UI | 2.0+ |
