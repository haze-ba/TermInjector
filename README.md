# TermInjector

macOS Terminal.app 向けの日本語IME対応テキスト入力オーバーレイアプリ。

## 概要

Claude Code等のTUIアプリケーションで発生する日本語入力の問題（IME変換確定のEnterが送信扱いになる誤送信、Shift+Enter改行の不安定さ、複数行入力時の折り返し破綻）を回避するため、入力部分だけをmacOSネイティブUI（NSTextView）に切り出したフローティングウィンドウを提供します。

確定済みテキストをクリップボード経由でTerminal.appに安全に注入します。

## 主な機能

- **IMEガード**: 変換中のEnterは確定操作として扱い、誤送信を防止
- **フローティングウィンドウ**: 常に最前面に表示される入力専用ウィンドウ
- **グローバルホットキー**: `Cmd+Opt+Space` でオーバーレイを表示/非表示（カスタマイズ可能）
- **安全な注入**: クリップボード退避 → テキスト設定 → Cmd+V → 復元
- **ファイルドラッグ&ドロップ**: Finderからファイルをドロップしてパスを挿入
- **画像ペースト/ドロップ**: スクリーンショットや画像を貼り付けると一時ファイルに保存しパスを挿入
- **柔軟な設定**: 送信キー、改行キー、安全チェック等をカスタマイズ

## 動作環境

- macOS 12.0 (Monterey) 以降
- Terminal.app
- アクセシビリティ権限（キー入力シミュレーションに必要）

## セットアップ

### 前提条件

- Xcode 15.0 以降
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

### ビルド

```bash
# Xcodeプロジェクト生成
xcodegen generate

# Xcodeで開く
open TermInjector.xcodeproj

# またはコマンドラインでビルド
xcodebuild build -scheme TermInjector -destination 'platform=macOS'
```

### テスト

```bash
xcodebuild test -scheme TermInjector -destination 'platform=macOS'
```

## 使い方

1. アプリを起動するとメニューバーにアイコンが表示されます
2. 初回起動時にアクセシビリティ権限の許可を求められます（システム設定 > プライバシーとセキュリティ > アクセシビリティ）
3. `Cmd+Opt+Space` でオーバーレイを表示
4. テキストを入力（日本語IMEの変換確定で誤送信されません）
5. `Enter` で Terminal.app にテキストを注入して実行
6. `Shift+Enter` で改行
7. `Escape` でオーバーレイを閉じる

### キーボードショートカット

オーバーレイ内では標準的な編集ショートカットが利用できます。

| ショートカット | 動作 |
|-------------|------|
| `Cmd+X` | カット |
| `Cmd+C` | コピー |
| `Cmd+V` | ペースト |
| `Cmd+A` | すべてを選択 |
| `Cmd+Z` | 取り消す |
| `Cmd+Shift+Z` | やり直す |

### 注意事項

- Terminal.app の「安全なキーボード入力」(Secure Keyboard Entry) が有効だとキー送信が効かない場合があります。Terminal.appのメニューからOFFにしてください。
- 送信先が Terminal.app でない場合は安全チェックにより送信がスキップされます（設定で変更可能）。

## 設定

メニューバーアイコンの「設定...」から設定画面を開けます。

| カテゴリ | 設定項目 | デフォルト |
|---------|---------|-----------|
| 送信 | Enterで送信 | ON |
| 送信 | Cmd+Enterで送信 | OFF |
| 送信 | Cmd+Enter強制（Enterを無効化） | OFF |
| 送信 | Shift+Enterで改行 | ON |
| 送信 | 貼り付けのみ（Enter送信しない） | OFF |
| 送信 | 安全チェック（Terminal.app確認） | ON |
| 一般 | ホットキー | Cmd+Opt+Space |
| 一般 | 送信後にウィンドウを閉じる | ON |

## プロジェクト構成

```
TermInjector/
├── App/                    # アプリライフサイクル、メニューバー
├── Overlay/                # フローティングウィンドウ、入力ビュー
├── Injection/              # Terminal.appへの注入処理
├── HotKey/                 # グローバルホットキー
├── Preferences/            # 設定管理、設定UI
├── FileHandling/           # ファイルドロップ、画像処理
├── Utilities/              # ユーティリティ（キー判定、権限チェック等）
└── Resources/              # Info.plist, Assets
TermInjectorTests/          # ユニットテスト（67件）
```

詳細なアーキテクチャについては [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) を参照してください。

## ライセンス

[MIT License](LICENSE)
