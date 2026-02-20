import SwiftUI
import KeyboardShortcuts
import ServiceManagement

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

            AdvancedSettingsTab()
                .tabItem {
                    Label("詳細", systemImage: "slider.horizontal.3")
                }
        }
        .frame(width: 420, height: 420)
    }
}

// MARK: - 送信設定タブ

private struct SendSettingsTab: View {

    @AppStorage("sendOnEnter") private var sendOnEnter = true
    @AppStorage("sendOnShiftEnter") private var sendOnShiftEnter = false
    @AppStorage("sendOnCmdEnter") private var sendOnCmdEnter = false
    @AppStorage("simulateEnterAfterPaste") private var simulateEnterAfterPaste = true
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
                Toggle("ペースト後にEnterを送信する", isOn: $simulateEnterAfterPaste)
                    .help("OFFにすると、テキストの貼り付けのみ行い、Enterは送信しません")
            } header: {
                Text("送信動作")
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
    @AppStorage("retainTextAfterSend") private var retainTextAfterSend = false
    @AppStorage("followTerminalWindow") private var followTerminalWindow = false
    @AppStorage("overlayPosition") private var overlayPosition = "bottom"
    @State private var launchAtLogin = false
    @State private var loginItemError: String?

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
                Toggle("送信後もテキストを保持する", isOn: $retainTextAfterSend)
                    .help("送信後にテキストをクリアせず残します。同じテキストを微修正して再送信する時に便利です")
                Toggle("ターミナルウィンドウに追従", isOn: $followTerminalWindow)
                    .help("オーバーレイをターミナルウィンドウの近くに配置します")
                if followTerminalWindow {
                    Picker("配置位置", selection: $overlayPosition) {
                        Text("上").tag("top")
                        Text("下").tag("bottom")
                        Text("左").tag("left")
                        Text("右").tag("right")
                    }
                    .pickerStyle(.segmented)
                }
            } header: {
                Text("ウィンドウ")
            }

            Section {
                Toggle("ログイン時に自動起動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginItemError = nil
                        } catch {
                            NSLog("[TermInjector] ログイン項目の設定に失敗: \(error)")
                            loginItemError = error.localizedDescription
                            // 失敗時はトグルを元に戻す
                            DispatchQueue.main.async {
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }
                    }
                if let errorMessage = loginItemError {
                    Text("エラー: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Text("起動")
            }
        }
        .padding()
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}


// MARK: - 詳細設定タブ

private struct AdvancedSettingsTab: View {

    @AppStorage("injectionPasteDelayMs") private var injectionPasteDelayMs = 100
    @AppStorage("injectionEnterDelayMs") private var injectionEnterDelayMs = 300
    @AppStorage("injectionRestoreDelayMs") private var injectionRestoreDelayMs = 300

    var body: some View {
        Form {
            Section {
                Stepper("ペースト前待機: \(injectionPasteDelayMs) ms",
                        value: $injectionPasteDelayMs, in: 50...1000, step: 50)
                Stepper("Enter前待機: \(injectionEnterDelayMs) ms",
                        value: $injectionEnterDelayMs, in: 50...1000, step: 50)
                Stepper("復元前待機: \(injectionRestoreDelayMs) ms",
                        value: $injectionRestoreDelayMs, in: 50...1000, step: 50)

                Text("値を大きくすると安定性が向上しますが、注入速度が遅くなります")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("デフォルトに戻す") {
                    injectionPasteDelayMs = 100
                    injectionEnterDelayMs = 300
                    injectionRestoreDelayMs = 300
                }
            } header: {
                Text("注入タイミング")
            }
        }
        .padding()
    }
}
