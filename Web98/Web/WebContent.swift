import Foundation
import WebKit
import Combine

public class WebContent: NSObject, ObservableObject {
    let webview: WKWebView
    private var observers = [NSKeyValueObservation]()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var commitCount = 0

    // MARK: - API
    public struct Info: Equatable, Codable {
        var url: URL?
        var title: String?
        var canGoBack = false
        var canGoForward = false
        var isLoading = false
    }

    @Published private(set) public var info = Info()
    public var shouldBlockNavigation: ((WKNavigationAction) -> Bool)?

    public func load(url: URL) {
        webview.load(.init(url: url))
    }

    public func load(html: String, baseURL: URL?) {
        webview.loadHTMLString(html, baseURL: baseURL)
    }

    public init(transparent: Bool = false, allowsInlinePlayback: Bool = false, autoplayAllowed: Bool = false) {
        let config = WKWebViewConfiguration()
        #if os(iOS)
        config.allowsInlineMediaPlayback = allowsInlinePlayback
        if autoplayAllowed {
            config.mediaTypesRequiringUserActionForPlayback = []
        }
        #endif
        webview = WKWebView(frame: .zero, configuration: config)
        webview.allowsBackForwardNavigationGestures = true
        self.transparent = transparent
        super.init()
        webview.navigationDelegate = self
        webview.uiDelegate = self

        #if os(macOS)
        // Safari
        webview.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Version/14.0.3 Safari/537.36"
        #endif

        observers.append(webview.observe(\.url, changeHandler: { [weak self] _, _ in
            self?.needsMetadataRefresh()
        }))

        observers.append(webview.observe(\.url, changeHandler: { [weak self] _, _ in
            self?.needsMetadataRefresh()
        }))

        observers.append(webview.observe(\.canGoBack, changeHandler: { [weak self] _, val in
            self?.info.canGoBack = val.newValue ?? false
        }))

        observers.append(webview.observe(\.canGoForward, changeHandler: { [weak self] _, val in
            self?.info.canGoForward = val.newValue ?? false
        }))

        observers.append(webview.observe(\.isLoading, changeHandler: { [weak self] _, val in
            self?.info.isLoading = val.newValue ?? false
        }))

#if os(macOS)
        // no op
        #else
        webview.scrollView.backgroundColor = nil
        NotificationCenter.default.addObserver(self, selector: #selector(appDidForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        #endif
        updateTransparency()

    }

    var transparent: Bool = false {
        didSet(old) {
            if transparent != old { updateTransparency() }
        }
    }

    private func updateTransparency() {
        #if os(macOS)
        // TODO: Implement transparency on macOS
        #else
        webview.backgroundColor = transparent ? nil : UIColor.white
        webview.isOpaque = !transparent
        #endif
    }

    #if os(macOS)
    var view: NSView { webview }
    #else
    var view: UIView { webview }
    #endif

    func goBack() {
        webview.goBack()
    }

    func goForward() {
        webview.goForward()
    }

    func configure(_ block: (WKWebView) -> Void) {
        block(webview)
    }

    // MARK: - Populate

    private var populateBlock: ((WebContent) -> Void)?
    private var waitingForRepopulationAfterProcessTerminate = false
    /// A webview's content process can be terminated while the app is in the background.
    /// `populate` allows you to handle this.
    /// Wrap your calls to load content into the webview within `populate`.
    /// The code will be called immediately, but _also_ after process termination.
    func populate(_ block: @escaping (WebContent) -> Void) {
        waitingForRepopulationAfterProcessTerminate = false
        populateBlock = block
        block(self)
    }

    // MARK: - Lifecycle
    @objc private func appDidForeground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.waitingForRepopulationAfterProcessTerminate, let block = self.populateBlock {
                block(self)
            }
            self.waitingForRepopulationAfterProcessTerminate = false
        }
    }

    // MARK: - Metadata
    private func needsMetadataRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.refreshMetadataNow()
        }
    }

    func refreshMetadataNow() {
        self.info = .init(url: webview.url, title: webview.title, canGoBack: webview.canGoBack, canGoForward: webview.canGoForward)
    }
}

extension WebContent: WKNavigationDelegate, WKUIDelegate {
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        commitCount += 1
        needsMetadataRefresh()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        needsMetadataRefresh()
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame?.isMainFrame ?? true,
            let block = shouldBlockNavigation,
            block(navigationAction) {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        waitingForRepopulationAfterProcessTerminate = true
    }

    // MARK: - WKUIDelegate
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Load in same window:
        if let url = navigationAction.request.url {
            webview.load(.init(url: url))
        }
        return nil
    }
}
