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
        .frame(width: 420, height: 380)
    }
}

// MARK: - 送信設定タブ

private struct SendSettingsTab: View {

    @AppStorage("sendOnEnter") private var sendOnEnter = true
    @AppStorage("sendOnShiftEnter") private var sendOnShiftEnter = false
    @AppStorage("sendOnCmdEnter") private var sendOnCmdEnter = false
    @AppStorage("safetyCheck") private var safetyCheck = true
    @StateObject private var allowedAppsManager = AllowedAppsManager()

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
                Toggle("安全チェック（送信前に対象アプリを確認）", isOn: $safetyCheck)
                    .help("送信前に登録済みアプリがフォアグラウンドだったか確認します")
            } header: {
                Text("安全設定")
            }

            Section {
                ForEach(allowedAppsManager.apps, id: \.bundleID) { app in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                            Text(app.bundleID)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(role: .destructive) {
                            allowedAppsManager.remove(bundleID: app.bundleID)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button("アプリを追加...") {
                    allowedAppsManager.addViaOpenPanel()
                }
            } header: {
                Text("対象アプリ")
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
