import Foundation

public extension Sequence {
    func localizedStandardSorted(on: (Element) -> String) -> [Element] {
        sorted { lhs, rhs in
            on(lhs).localizedStandardCompare(on(rhs)) == .orderedAscending
        }
    }
}
