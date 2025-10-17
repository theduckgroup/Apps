import Foundation


public extension Sequence where Element: Numeric {
    func sum() -> Element {
        reduce(.zero, +)
    }
}

public extension Collection where Element: FloatingPoint {
    func mean() -> Element? {
        count > 0 ? sum() / Element(count) : nil
    }
}

public extension Collection<CGPoint> {
    func mean() -> CGPoint? {
        guard let x = map(\.x).mean(),
              let y = map(\.y).mean() else {
            return nil
        }
        
        return CGPoint(x: x, y: y)
    }
}
