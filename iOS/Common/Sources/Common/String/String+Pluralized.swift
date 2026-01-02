import Foundation

public extension String {
    func pluralized(count: Int = 1) -> String {
        if count == 1 {
            return self
        }

        let lowerWord = self.lowercased()

        if let plural = pluralDictionary[lowerWord] {
            return plural
        }

        // s, x, z... rules

        if lowerWord.hasSuffix("s") || lowerWord.hasSuffix("x") || lowerWord.hasSuffix("z") ||
           lowerWord.hasSuffix("ch") || lowerWord.hasSuffix("sh") {
            return self + "es"
        }

        // y rule

        if lowerWord.hasSuffix("y") && lowerWord.count > 1 {
            let index = lowerWord.index(lowerWord.endIndex, offsetBy: -2)
            let beforeY = String(lowerWord[index])
            
            if !["a", "e", "i", "o", "u"].contains(beforeY) {
                return String(self.dropLast()) + "ies"
            }
        }

        return self + "s"
    }
}

private let pluralDictionary: [String: String] = [
    "person": "people",
    "child": "children",
    "tooth": "teeth",
    "foot": "feet",
    "mouse": "mice",
    "goose": "geese",
    "man": "men",
    "woman": "women"
]