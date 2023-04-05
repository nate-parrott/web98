import Foundation

extension String {
    func byDroppingPrefix(_ prefix: String) -> String {
        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        } else {
            return self
        }
    }

    var nilIfEmpty: String? {
        self == "" ? nil : self
    }

    var nilIfEmptyOrJustWhitespace: String? {
        if trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return nil
        }
        return self
    }
}
