import WebKit
import Foundation

extension WKWebView {
    func runAsync(js: String) async throws -> Any? {
        try await withCheckedThrowingContinuation({ cont in
            DispatchQueue.main.async {
                self.evaluateJavaScript(js) { result, err in
                    if let err {
                        cont.resume(throwing: err)
                    } else {
                        cont.resume(returning: result)
                    }
                }
            }
        })
    }
}

extension String {
    var wrappedInSelfCallingJSFunction: String {
        "(function() { \(self) })()"
    }
}

extension Encodable {
    var encodedAsJSONString: String {
        let data = try! JSONEncoder().encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
