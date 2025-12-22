import Foundation

public extension String {
    /// Replaces with another string if empty.
    func ifEmpty(_ replacement: @autoclosure () -> String) -> String {
        self.isEmpty ? replacement() : self
    }
}
