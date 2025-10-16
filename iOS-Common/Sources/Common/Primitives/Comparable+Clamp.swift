import Foundation

public extension Comparable {
    /// Clamps to a range.
    ///
    /// Examples:
    /// ```
    /// 5.clamped(to: 7...9) // Returns 7
    /// 11.clamped(to: 7...9 // Returns 9
    /// ```
    ///
    /// - Note: Swift has `clamped` method on `Range`
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamped(min: range.lowerBound, max: range.upperBound)
    }
    
    /// Clamp into a range, with optional min/max values.
    ///
    /// For example:
    /// ```
    /// 5.clamped(min: 3) // Returns 5
    /// 5.clamped(min: 7) // Returns 7
    /// 5.clamped(max: 3) // Returns 3
    /// 5.clamped(max: 7) // Returns 5
    /// ```
    func clamped(min: Self? = nil, max: Self? = nil) -> Self {
        if let min = min {
            if self < min { return min }
        }
        
        if let max = max {
            if max < self { return max }
        }
        
        return self
    }
    
    mutating func clamp(to range: ClosedRange<Self>) {
        self = self.clamped(to: range)
    }
    
    mutating func clamp(min: Self? = nil, max: Self? = nil) {
        self = self.clamped(min: min, max: max)
    }
}

public extension Strideable where Self.Stride: SignedInteger {
    func clamped(to range: CountableClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
