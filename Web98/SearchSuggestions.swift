import SwiftUI
import OpenAIStreamingCompletions
import UIKit

struct SearchSuggestions: View {
    var query: String
    var onSelect: (String) -> Void

    @AppStorage("prompt") private var prompt: String = baseWorld
    @State private var suggestions: [String]?

    var body: some View {
        List {
            ForEach(suggestions ?? [], id: \.self) { query in
                Text(query).onTapGesture {
                    onSelect(query)
                }
            }
            ForEach(placeholderSuggestions, id: \.self) { query in
                Text(query).redacted(reason: .placeholder)
            }
        }
        .listStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .onAppearOrChange(prompt) { prompt in
            self.suggestions = nil
            Task {
                do {
                    for await suggestions in try fetchSuggestions(world: prompt) {
                        DispatchQueue.main.async {
                            self.suggestions = suggestions
                        }
                    }
                } catch {
                    print("Search suggestions error: \(error)")
                }
            }
        }
    }

    private var placeholderSuggestions: [String] {
        var s = [String]()
        while (s.count + (suggestions ?? []).count) < 4 {
            s.append("placeholder-\(s.count)")
        }
        return s
    }
}

private func fetchSuggestions(world: String) throws -> AsyncStream<[String]> {
    let prompt = genSearchSuggestionsPrompt(world: world)
    return try OpenAIAPI.shared.completeChatStreaming(.init(messages: prompt)).compactMap { message -> [String]? in
        var text: String = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = String(text.dropFirst(3))
        }
        if text.hasSuffix("```") {
            text = String(text.dropLast(3))
        }
        for appendClosingBracket in [false, true] {
            do {
                let str = text + (appendClosingBracket ? "]" : "")
                let parsed = try JSONDecoder().decode([String].self, from: str.data(using: .utf8)!)
                return parsed
            } catch {
                return nil
            }
        }
        return nil
    }.eraseToStream()
}
