import Foundation

public extension String {
    func trimmingPrefixes(_ prefixes: some Sequence<String>) -> String {
        for prefix in prefixes {
            if hasPrefix(prefix) {
                return String(self.dropFirst(prefix.count))
            }
        }
        
        return self
    }
    
    func trimmingSuffixes(_ suffixes: some Sequence<String>) -> String {
        for suffix in suffixes {
            if self.hasSuffix(suffix) {
                return String(self.dropLast(suffix.count))
            }
        }
        
        return self
    }
    
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension Substring {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespaces)
    }
}
