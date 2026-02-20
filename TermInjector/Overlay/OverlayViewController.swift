import Cocoa

final class OverlayViewController: NSViewController, InputTextViewDelegate {

    private var scrollView: NSScrollView!
    private var inputTextView: InputTextView!
    private var footerLabel: NSTextField!
    private let preferencesStore = PreferencesStore()

    var onSend: ((String) -> Void)?

    override func loadView() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0,
                                                  width: Constants.Defaults.overlayWidth,
                                                  height: Constants.Defaults.overlayHeight))
        self.view = containerView
        setupScrollView()
        setupFooterLabel()
        setupConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextView.inputDelegate = self
    }

    private func setupScrollView() {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(
            width: Constants.Defaults.overlayWidth - 16,
            height: CGFloat.greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        inputTextView = InputTextView(frame: .zero, textContainer: textContainer)
        inputTextView.isVerticallyResizable = true
        inputTextView.isHorizontallyResizable = false
        inputTextView.autoresizingMask = [.width]
        inputTextView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        inputTextView.minSize = NSSize(width: 0, height: 0)

        scrollView = NSScrollView()
        scrollView.documentView = inputTextView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
    }

    private func setupFooterLabel() {
        footerLabel = NSTextField(labelWithString: "")
        footerLabel.font = NSFont.systemFont(ofSize: 11)
        footerLabel.textColor = .secondaryLabelColor
        footerLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(footerLabel)
    }

    /// フッターラベルを現在の設定に合わせて更新する
    private func updateFooterLabel() {
        var sendKeys: [String] = []
        if preferencesStore.sendOnEnter { sendKeys.append("Enter") }
        if preferencesStore.sendOnShiftEnter { sendKeys.append("Shift+Enter") }
        if preferencesStore.sendOnCmdEnter { sendKeys.append("Cmd+Enter") }

        let sendPart = sendKeys.isEmpty ? "送信キー未設定" : sendKeys.joined(separator: "/") + ": 送信"
        footerLabel.stringValue = "\(sendPart) | Esc: 閉じる"
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerLabel.topAnchor, constant: -4),

            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            footerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            footerLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6),
            footerLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    func focusInput() {
        syncPreferences()
        updateFooterLabel()
        view.window?.makeFirstResponder(inputTextView)
    }

    /// PreferencesStoreからInputTextViewのキー設定を同期する
    private func syncPreferences() {
        inputTextView.keyPreferences = preferencesStore.toKeyHandlingPreferences()
    }

    func clearInput() {
        inputTextView.clearText()
    }

    // MARK: - InputTextViewDelegate

    func inputTextViewDidRequestSend(_ textView: InputTextView, text: String) {
        onSend?(text)
    }

    func inputTextViewDidRequestClose(_ textView: InputTextView) {
        view.window?.orderOut(nil)
    }
}
