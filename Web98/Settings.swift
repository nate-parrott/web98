import SwiftUI

struct Settings: View {
    @AppStorage("apiKey") private var apiKey: String = ""
    @AppStorage("orgId") private var orgId: String = ""
    @AppStorage("model") private var model: String = baseModel


    var body: some View {
        Form {
            Section {
                NavigationLink("Edit World Description") {
                    EditPrompt()
                }
            }
            Section(header: Text("OpenAI")) {
                TextField("API Key", text: $apiKey)
                TextField("Organization ID", text: $orgId)
                TextField("Model", text: $model)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EditPrompt: View {
    @AppStorage("prompt") private var prompt: String = baseWorld

    var body: some View {
        TextEditor(text: $prompt)
            .navigationTitle("World Description")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Reset") { prompt = baseWorld }
                }
            }
    }
}
