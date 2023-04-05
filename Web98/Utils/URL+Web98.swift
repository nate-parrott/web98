import Foundation

extension URL {
    public static func searchURL(_ query: String) -> URL {
        var comps = URLComponents(string: "http://search.com/find")!
        comps.queryItems = [URLQueryItem(name: "q", value: query)]
        return comps.url!
    }

    var parsedAsSearchURL: String? {
        guard host == "search.com" else { return nil }
        if let q = queryParam(name: "q") {
            return q
        }
        return nil
    }
}

extension URLRequest {
    var convertPostBodyToQuery: URL? {
        guard let url else { return nil }
        if let httpBody = httpBody, let body = String(data: httpBody, encoding: .utf8) {
            var comps = URLComponents(string: url.absoluteString)!
            comps.queryItems = comps.queryItems ?? []
            comps.queryItems?.append(contentsOf: body.split(separator: "&").map { .init(name: String($0.split(separator: "=")[0]), value: String($0.split(separator: "=")[1])) })
            comps.queryItems?.append(.init(name: "method", value: "POST"))
            return comps.url
        }
        return url
    }
}
