import SwiftUI

struct Toolbar: View {
    @ObservedObject var webContent: WebContent
    @Binding var loading: Bool
    @Binding var editingPrompt: Bool
    @EnvironmentObject private var browserState: BrowserState

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                backForward
                    .opacity(browserState.searchFocused ? 0 : 1)

                Button(action: { browserState.unfocusId += 1 }) {
                    Text("Cancel")
                }
                .padding(.leading, 4)
                .opacity(browserState.searchFocused ? 1 : 0)
            }

            URLField(webContent: webContent)

            trailingControls
                .opacity(browserState.searchFocused ? 0 : 1)
        }
        .padding(.horizontal, 6)
        .frame(height: 44)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary)
                .opacity(browserState.searchFocused ? 0.2 : 0.1)
        }
    }

    @ViewBuilder private var backForward: some View {
        HStack(spacing: 0) {
            Button(action: { webContent.goBack() }) {
                Image(systemName: "chevron.backward")
                    .asToolbarButton
            }
            .disabled(!webContent.info.canGoBack)

            Button(action: { webContent.goForward() }) {
                Image(systemName: "chevron.forward")
                    .asToolbarButton
            }
            .disabled(!webContent.info.canGoForward)
        }
    }

    @ViewBuilder private var trailingControls: some View {
        HStack(spacing: 0) {
            Button(action: { loading = false }) {
                Image(systemName: "xmark")
                    .asToolbarButton
            }
            .opacity(loading ? 1 : 0)

            Button(action: { editingPrompt = true }) {
                Image(systemName: "quote.bubble")
                    .asToolbarButton
            }
        }
    }
}

extension View {
    var asToolbarButton: some View {
        self
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
}

private struct URLField: View {
    @ObservedObject var webContent: WebContent
    @EnvironmentObject private var browserState: BrowserState

    @State private var unfocusId = 0

    var body: some View {
        BridgedTextField(text: queryBinding, options: options )
            .onChange(of: webContent.info.url) { newValue in
                if let newUrl = newValue, !browserState.searchFocused {
                    queryBinding.wrappedValue = newUrl.parsedAsSearchURL ?? newUrl.stripped
                }
            }
    }

    private var queryBinding: Binding<String> {
        .init(get: { browserState.searchQuery }, set: { browserState.searchQuery = $0 })
    }

    private var options: BridgedTextField.Options {
        .init(placeholder: "Search or type URL", unfocusId: browserState.unfocusId, onFocusChanged: { browserState.searchFocused = $0 }, autocapitalization: .none, autocorrection: .no, spellChecking: .no, keyboardType: .webSearch, onReturn: onSubmit, alignment: .center, selectAllOnFocus: true)
    }

    private func onSubmit() {
        browserState.navigateTo(query: queryBinding.wrappedValue, webContent: webContent)
    }
}

struct LoadingBar: View {
    var loading: Bool
    var duration: TimeInterval = 10

    @State private var loadId: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ManualTransitionView(models: models, removalDuration: 1) { model, phase in
                    bar(phase: phase, fullWidth: geometry.size.width)
                }
            }
        }
        .frame(height: 2)
        .onChange(of: loading) { loading in
            if loading {
                loadId = UUID().uuidString
            } else {
                loadId = nil
            }
        }
    }

    private struct IdStringWrapper: Identifiable, Equatable {
        var str: String
        var id: String { str }
    }
    private var models: [IdStringWrapper] {
        if let loadId { return [.init(str: loadId)] }
        return []
    }

    @ViewBuilder private func bar(phase: ManualTransitionPhase, fullWidth: CGFloat) -> some View {
        let width =  phase == .removed ? fullWidth : (phase == .inserted ? fullWidth * 0.7 : 0)
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: width)
            .animation(.easeOut(duration: phase == .removed ? 0.2 : duration), value: phase)
            .frame(width: fullWidth, alignment: .leading)
            .opacity(phase == .inserted ? 1 : 0)
            .animation(.default.delay(phase == .removed ? 0.3 : 0), value: phase)
    }
}

private struct LoadingBarDemo: View {
    @State private var loading = false

    var body: some View {
        VStack {
            LoadingBar(loading: loading)
            Spacer()
            Button("Toggle") { loading.toggle() }
            Spacer()
        }
    }
}

struct LoadingBar_Previews: PreviewProvider {
    static var previews: some View {
        LoadingBarDemo()
    }
}
