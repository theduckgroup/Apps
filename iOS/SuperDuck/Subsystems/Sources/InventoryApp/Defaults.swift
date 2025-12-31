public import Foundation
import Common

@Observable
@dynamicMemberLookup
public class Defaults {
    private let storageKey = "InventoryApp:defaults"
    
    public init() {
        data = Persistence.value(for: storageKey) ?? .init()
    }
    
    private var data: Data {
        didSet {
            Persistence.setValue(data, for: storageKey)
        }
    }
    
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Data, T>) -> T {
        get {
            data[keyPath: keyPath]
        }
        set {
            data[keyPath: keyPath] = newValue
        }
    }
}

extension Defaults {
    struct Data: Codable {
        var scanner = Scanner()
    }
    
    struct Scanner: Hashable, Codable {
        var minPresenceTime: TimeInterval = BarcodeScanner.defaultMinPresenceTime
        var minAbsenceTime: TimeInterval = BarcodeScanner.defaultMinAbsenceTime
    }
}
