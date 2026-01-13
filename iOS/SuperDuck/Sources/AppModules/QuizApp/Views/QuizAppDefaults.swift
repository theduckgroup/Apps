public import SwiftUI
import Common
public import CommonUI

@Observable
@dynamicMemberLookup
public class QuizAppDefaults {
    public let storageKey: String = "QuizApp:defaults"

    public init() {
        data = Persistence.value(for: storageKey) ?? .init()
    }

    private var data: Data {
        didSet {
            Persistence.setValue(data, for: storageKey)
        }
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Data, T>) -> T {
        get {
            data[keyPath: keyPath]
        }
        set {
            data[keyPath: keyPath] = newValue
        }
    }
}

public extension QuizAppDefaults {
    struct Data: Codable {
        public var colorSchemeOverride: ColorSchemeOverride?
        public var dynamicTypeSizeOverride: DynamicTypeSizeOverride?
    }
}
