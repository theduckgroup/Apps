import Foundation

// Swift Collection protocols:
// https://www.objc.io/blog/2019/03/26/collection-protocols/
// https://oleb.net/blog/2017/02/why-is-dictionary-not-a-mutablecollection/
// https://itwenty.me/2021/10/understanding-swifts-collection-protocols/

public extension MutableCollection where Self: RandomAccessCollection {
    /// Sorts by projecting elements into keys
    mutating func sort(on key: (Element) -> some Comparable, ascending: Bool = true) {
        sort(by: { x, y in
            ascending ? key(x) < key(y) : key(y) < key(x)
        })
    }
}

public extension RangeReplaceableCollection {
    mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows {
        if let index = try firstIndex(where: predicate) {
            self.remove(at: index)
        }
    }
}

public extension RangeReplaceableCollection where Self: BidirectionalCollection {
    mutating func removeLast(where predicate: (Element) throws -> Bool) rethrows {
        if let index = try lastIndex(where: predicate) {
            self.remove(at: index)
        }
    }
}

