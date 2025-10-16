import Foundation

// MARK: Set-like operations

public extension Sequence {
    
    /// Intersects with another sequence by projecting elements into keys.
    ///
    /// Implemented by mapping into `Set`. Order is not preserved. Comlexity is the the same as `Set` intersection.
    func intersection<Other : Sequence>(_ other: Other, on key: (Element) -> some Hashable) -> [Element] where Element == Other.Element {
        let keyedElements = Set(self.map { KeyedElement(key: key($0), element: $0) })
        let otherKeyedElements = Set(other.map { KeyedElement(key: key($0), element: $0) })
        
        return keyedElements.intersection(otherKeyedElements).map { $0.element }
    }
    
    /// Subtracts another sequence by projecting elements into keys.
    ///
    /// Implemented by mapping into `Set`. Order is not preserved. Comlexity is the the same as `Set` subtraction.
    func subtracting<Other : Sequence>(_ other: Other, on key: (Element) -> some Hashable) -> [Element] where Element == Other.Element {
        let keyedElements = Set(self.map { KeyedElement(key: key($0), element: $0) })
        let otherKeyedElements = Set(other.map { KeyedElement(key: key($0), element: $0) })
        
        return keyedElements.subtracting(otherKeyedElements).map { $0.element }
    }
    
    /// Unions with another sequence by projecting elements into keys.
    ///
    /// Implemented by mapping into `Set`. Order is not preserved. Comlexity is the the same as `Set` union.
    func union<Other : Sequence>(_ other: Other, on key: (Element) -> some Hashable) -> [Element] where Element == Other.Element {
        let keyedElements = Set(self.map { KeyedElement(key: key($0), element: $0) })
        let otherKeyedElements = Set(other.map { KeyedElement(key: key($0), element: $0) })
        
        return keyedElements.union(otherKeyedElements).map { $0.element }
    }
}

/// Data structure used in set-like algorithms
private struct KeyedElement<Key: Hashable, Element>: Hashable {
    let key: Key
    let element: Element
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    static func ==(_ x: KeyedElement, _ y: KeyedElement) -> Bool {
        x.key == y.key
    }
}
