import SwiftUI
import KeyboardShortcuts

struct PreferencesView: View {

    var body: some View {
        TabView {
            SendSettingsTab()
                .tabItem {
                    Label("送信", systemImage: "paperplane")
                }

            GeneralSettingsTab()
                .tabItem {
                    Label("一般", systemImage: "gear")
                }
        }
        .frame(width: 420, height: 320)
    }
}

// MARK: - 送信設定タブ

private struct SendSettingsTab: View {

    @AppStorage("enterSend") private var enterSend = true
    @AppStorage("cmdEnterSend") private var cmdEnterSend = false
    @AppStorage("cmdEnterForced") private var cmdEnterForced = false
    @AppStorage("shiftEnterNewline") private var shiftEnterNewline = true
    @AppStorage("pasteOnly") private var pasteOnly = false
    @AppStorage("safetyCheck") private var safetyCheck = true

    var body: some View {
        Form {
            Section {
                Toggle("Enterで送信", isOn: $enterSend)
                    .disabled(cmdEnterForced)
                    .help("Enterキーでテキストを送信します")

                Toggle("Cmd+Enterで送信", isOn: $cmdEnterSend)
                    .help("Cmd+Enterキーでテキストを送信します")

                Toggle("Cmd+Enter強制（Enter送信を無効化）", isOn: $cmdEnterForced)
                    .onChange(of: cmdEnterForced) { newValue in
                        if newValue {
                            cmdEnterSend = true
                            enterSend = false
                        }
                    }
                    .help("ONにすると、送信はCmd+Enterのみになります")
            } header: {
                Text("送信キー")
            }

            Section {
                Toggle("Shift+Enterで改行", isOn: $shiftEnterNewline)
                    .help("Shift+Enterで改行を挿入します")
            } header: {
                Text("改行")
            }

            Section {
                Toggle("貼り付けのみモード（Enter送信を無効化）", isOn: $pasteOnly)
                    .help("ONにすると、テキストの貼り付けのみ行い、Enterキーは送信しません")

                Toggle("安全チェック（送信前にTerminal.appを確認）", isOn: $safetyCheck)
                    .help("送信前にTerminal.appがフォアグラウンドだったか確認します")
            } header: {
                Text("安全設定")
            }
        }
        .padding()
    }
}

// MARK: - 一般設定タブ

private struct GeneralSettingsTab: View {

    @AppStorage("closeAfterSend") private var closeAfterSend = true

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("ホットキー:")
                    KeyboardShortcuts.Recorder(for: .toggleOverlay)
                }
                .help("入力ウィンドウの表示/非表示を切り替えるキーボードショートカット")
            } header: {
                Text("ショートカット")
            }

            Section {
                Toggle("送信後にウィンドウを閉じる", isOn: $closeAfterSend)
                    .help("テキスト送信後に入力ウィンドウを自動的に閉じます")
            } header: {
                Text("ウィンドウ")
            }
        }
        .padding()
    }
}
