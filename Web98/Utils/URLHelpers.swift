import Foundation

private func stringHasURLScheme(_ str: String) -> Bool {
    if let comps = URLComponents(string: str) {
        return comps.scheme?.count ?? 0 > 0
    }
    return false
}

extension URL {
    public static func withNaturalString(_ string: String) -> URL? {
        if !(string.contains(":") || string.contains(".")) {
            return nil
        }
        if stringHasURLScheme(string) {
            return URL(string: string)
        }
        return URL(string: "https://" + string)
    }
    public static func withSearchQuery(_ searchQuery: String) -> URL {
        return withNaturalString(searchQuery) ?? googleSearch(searchQuery)
    }
    
    public static func googleSearch(_ query: String) -> URL {
        var comps = URLComponents(string: "https://google.com/search")!
        comps.queryItems = [URLQueryItem(name: "q", value: query)]
        return comps.url!
    }

    public func withScheme(_ scheme: String) -> URL? {
        guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return nil }
        comps.scheme = scheme
        return comps.url
    }

    // don't use this for navigation -- only deduplication
    public var historyKey: String {
        guard var comps = URLComponents(string: absoluteString.lowercased()) else { return absoluteString }
        if comps.scheme == "https" {
            comps.scheme = "http"
        }
        comps.fragment = nil

        var hostParts = (comps.host ?? "").split(separator: ".")
        if hostParts.first == "www" {
            hostParts.removeFirst()
        }
        comps.host = hostParts.joined(separator: ".")

        comps.queryItems = comps.queryItems?.filter({ !shouldDropQueryItemForHistoryKey($0.name, val: $0.value) })
        var str = comps.url?.absoluteString ?? absoluteString
        if str.hasSuffix("/") {
            str.removeLast()
        }
        return str
    }

    public var normalizedKey: String {
        return historyKey
    }

    public var stringsToSearchBasedOn: [String] {
        var strings = [absoluteString.lowercased(), historyKey]
        let withoutScheme = absoluteString.lowercased().components(separatedBy: "://").dropFirst().joined(separator: "://")
        strings.append(withoutScheme)
        if withoutScheme.hasPrefix("www.") {
            // can u believe people enjoy using this language
            strings.append(String(withoutScheme.suffix(from: withoutScheme.index(withoutScheme.startIndex, offsetBy: 4))))
        }
        return strings
    }

    public var stripped: String {
//        guard var comps = URLComponents(string: absoluteString.lowercased()) else { return absoluteString }
//        comps.scheme = nil
        var str = absoluteString
        for prefix in ["https://", "http://", "www."] {
            if str.hasPrefix(prefix) {
                str = String(str.suffix(from: str.index(str.startIndex, offsetBy: prefix.count)))
            }
        }
        if str.hasSuffix("/") {
            str = String(str.dropLast())
        }
        return str
    }

    public func isAncestorOf(_ child: URL) -> Bool {
        let normSelf = self.standardizedFileURL.resolvingSymlinksInPath().absoluteString
        let normChild = child.standardizedFileURL.resolvingSymlinksInPath().absoluteString
        return normChild.hasPrefix(normSelf)
    }

    public var isDescendantOfApplicationsDir: Bool {
        return URL(fileURLWithPath: "/Applications").isAncestorOf(self) || URL(fileURLWithPath: "~/Applications").isAncestorOf(self)
    }

    public var hostWithoutWWW: String {
        var parts = (host ?? "").components(separatedBy: ".")
        if parts.first == "www" {
            parts.remove(at: 0)
        }
        return parts.joined(separator: ".")
    }

    public var isRootOfDomain: Bool {
        return pathComponents.count == 0
    }

    public var inferredFaviconURL: URL {
        return URL(string: "/favicon.ico", relativeTo: self)!
    }

    public func hasRootHost(_ host: String) -> Bool {
        let hw = hostWithoutWWW
        if hw == host {
            return true
        }
        if hw.hasSuffix("." + host) {
            return true
        }
        return false
    }

    public func queryParam(name: String) -> String? {
        guard let comps = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return nil }
        return comps.queryItems?.first(where: { $0.name == name })?.value
    }
}

private func shouldDropQueryItemForHistoryKey(_ name: String, val: String?) -> Bool {
    if (val ?? "") == "" {
        return true
    }
    if name.hasPrefix("utm_") {
        return true
    }
    return false
}
