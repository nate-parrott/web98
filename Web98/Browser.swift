import SwiftUI
#if os(macOS)
import AppKit
#endif
import OpenAIStreamingCompletions

class BrowserState: ObservableObject {
    @Published var searchFocused = false
    @Published var searchQuery = ""
    @Published var unfocusId = 0

    func navigateTo(query: String, webContent: WebContent) {
        guard query != "" else { return }
        let parsed = URL.withNaturalString(query) ?? URL.searchURL(query)
        if parsed != webContent.info.url {
            webContent.webview.loadSimulatedRequest(.init(url: parsed), responseHTML: "<body></body>")
//                            webContent.load(url: parsed)
        }
        unfocusId += 1
    }
}

struct Browser: View {
    @AppStorage("prompt") private var prompt: String = baseWorld
    @AppStorage("model") private var model: String = baseModel

    @StateObject private var state = BrowserState()
    @StateObject private var wc = WebContent()
    @State private var generatingForURL: URL?
    @State private var loading = false
    @State private var editingPrompt = false

    var body: some View {
        VStack(spacing: 0) {
            Toolbar(webContent: wc, loading: $loading, editingPrompt: $editingPrompt)
                .padding(6)
            Divider()

            ZStack {
                webView
                searchOverlay
            }
            .onChange(of: wc.info.url) { unwrappedURL in
                if let unwrappedURL {
                    showURL(unwrappedURL)
                }
            }
            .onAppear {
                wc.shouldBlockNavigation = { action in
                    if action.navigationType == .linkActivated, let url = action.request.url {
                        print(url)
                        wc.webview.loadSimulatedRequest(.init(url: url), responseHTML: "<body></body>")
                        return true
                    }
                    if action.navigationType == .formSubmitted, let url = action.request.convertPostBodyToQuery {
                        print(url)
//                        wc.load(url: url)
                        wc.webview.loadSimulatedRequest(.init(url: url), responseHTML: "<body></body>")
                        return true
                    }
                    return false
                }
            }
        }
        .sheet(isPresented: $editingPrompt) {
            NavigationView {
                Settings()
            }
        }
        .environmentObject(state)
    }

    @ViewBuilder private var webView: some View {
        WebView(content: wc) { event in
            handleWebEvent(event)
        }
        .overlay(alignment: .top) {
            LoadingBar(loading: loading)
        }
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder private var searchOverlay: some View {
        SearchSuggestions(query: state.searchQuery, onSelect: { url in
            state.navigateTo(query: url, webContent: wc)
        })
        .opacity(state.searchFocused ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: state.searchFocused)
    }

    private func handleWebEvent(_ event: WebViewEvent) {
        // TODO
    }

    private func showURL(_ url: URL) {
        self.generatingForURL = url
        if let cached = Cache.shared.cache[url] {
            wc.webview.evaluateJavaScript("document.documentElement.innerHTML = \(cached.encodedAsJSONString)")
            return
        }
        loading = true
        Task {
            let world = prompt.nilIfEmptyOrJustWhitespace ?? baseWorld
            for await x in try! OpenAIAPI.shared.completeChatStreaming(.init(messages: genPrompt(url: url, world: world), model: model, temperature: 0.7)) {
                DispatchQueue.main.async {
                    var html = x.content
                    html = html.trimmingCharacters(in: .whitespacesAndNewlines).byDroppingPrefix("```").byDroppingPrefix("html")
                    html = "<meta name='viewport' content='width=device-width, initial-scale=1' />" + html
                    html = Gifs.shared.replaceShortURLsWithLongURLs(inString: html)

                    Cache.shared.cache[url] = html
                    if self.generatingForURL == url, self.loading {
                        // print("html: \(x)")
                        wc.webview.evaluateJavaScript("document.documentElement.innerHTML = \(html.encodedAsJSONString)")
                    }
                }
            }
            DispatchQueue.main.async {
                if self.generatingForURL == url {
                    self.loading = false
                }
            }
        }
    }
}
