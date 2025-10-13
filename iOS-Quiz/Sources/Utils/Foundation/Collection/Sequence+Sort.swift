import Foundation
import CoreGraphics
import CoreLocation
import Algorithms

// MARK: Sorting

public extension Sequence {
    /// Elements sorted using given projection.
    func sorted(on key: (Element) -> some Comparable, ascending: Bool = true) -> [Element] {
        sorted(by: { x, y in
            ascending ? key(x) < key(y) : key(y) < key(x)
        })
    }
    
    /// Elements sorted using given projection to string and ``String.localizedCompare``.
    func localizedSorted(on projection: (Element) -> String) -> [Element] {
        sorted(by: { x, y in
            projection(x).localizedCompare(projection(y)) == .orderedAscending
        })
    }
    
    /// Elements sorted using given projection to string and ``String.localizedStandardCompare``.
    func localizedStandardSorted(on projection: (Element) -> String) -> [Element] {
        sorted(by: { x, y in
            projection(x).localizedStandardCompare(projection(y)) == .orderedAscending
        })
    }
    
    /// Elements sorted using given projection to a tuple.
    func sorted<Key1: Comparable, Key2: Comparable>(on keys: (Element) -> (Key1, Key2), ascending: Bool = true) -> [Element] {
        sorted(by: { x, y in
            var x = x, y = y
            
            if !ascending {
                swap(&x, &y)
            }
            
            let (x_key1, x_key2) = keys(x)
            let (y_key1, y_key2) = keys(y)
            
            if x_key1 < y_key1 {
                return true
                
            } else if x_key1 > y_key1 {
                return false
                
            } else {
                if x_key2 < y_key2 {
                    return true
                    
                } else  {
                    return false
                }
            }
        })
    }
    
    /// Max by projecting elements into keys
    func max(on key: (Element) -> some Comparable) -> Element? {
        self.max(by: { key($0) < key($1) })
    }
    
    /// Min by projecting elements into keys
    func min(on key: (Element) -> some Comparable) -> Element? {
        self.min(by: { key($0) < key($1) })
    }
}

public extension Sequence where Element == String {
    /// Elements sorted using ``String.localizedCompare``.
    func localizedSorted() -> [Element] {
        localizedSorted(on: { $0 })
    }
    
    /// Elements sorted using ``String.localizedStandardCompare``.
    func localizedStandardSorted() -> [Element] {
        localizedStandardSorted(on: { $0 })
    }
}
