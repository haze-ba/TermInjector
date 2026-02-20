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
        .frame(width: 420, height: 280)
    }
}

// MARK: - 送信設定タブ

private struct SendSettingsTab: View {

    @AppStorage("sendOnEnter") private var sendOnEnter = true
    @AppStorage("sendOnShiftEnter") private var sendOnShiftEnter = false
    @AppStorage("sendOnCmdEnter") private var sendOnCmdEnter = false
    @AppStorage("safetyCheck") private var safetyCheck = true

    var body: some View {
        Form {
            Section {
                Toggle("Enter", isOn: $sendOnEnter)
                Toggle("Shift + Enter", isOn: $sendOnShiftEnter)
                Toggle("Cmd + Enter", isOn: $sendOnCmdEnter)

                Text("送信キーに設定されていないキーは改行になります")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("送信キー")
            }

            Section {
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
