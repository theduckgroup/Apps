import Foundation

public extension Sequence {
    /// Finds duplicated elements by projecting elements into keys.
    ///
    /// Complexity: `O(n)`
    ///
    /// - Parameter key: a closure that projects element into a hashable key
    /// - Returns: Groups of duplicated elements
    func duplicates<Key: Hashable>(on key: (Element) -> Key) -> [[Element]] {
        var result: [Key: [Element]] = [:]
        
        for element in self {
            let key = key(element)
            result[key] = result[key, default: []] + [element]
        }
        
        return result.filter { _, array in array.count > 1 }.map { _, array in array }
    }
}

public extension Sequence where Element: Hashable {
    /// Finds duplicated elements.
    ///
    /// - Returns: Groups of duplicated elements
    func duplicates() -> [[Element]] {
        duplicates(on: { $0 })
    }
}

