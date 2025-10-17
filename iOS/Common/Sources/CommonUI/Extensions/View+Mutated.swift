import Foundation
import SwiftUI

public extension View {
    func mutated<Value>(_ keyPath: WritableKeyPath<Self, Value>, _ value: Value) -> Self {
        var s = self
        s[keyPath: keyPath] = value
        return s
    }
}
