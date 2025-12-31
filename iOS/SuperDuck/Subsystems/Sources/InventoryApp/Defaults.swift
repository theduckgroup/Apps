public import Foundation
import Common

@Observable
public class Defaults {
    private let storageKey = "InventoryApp:defaults"

    public init() {
        data = Persistence.value(for: storageKey) ?? .init()
    }
    
    var scanner: Scanner {
        get { data.scanner }
        set { data.scanner = newValue }
    }
    
    private var data: Data {
        didSet {
            Persistence.setValue(data, for: storageKey)
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
