public import Foundation
import Common

@Observable
public class Defaults {
    private var data: Data {
        didSet {
            // TODO
        }
    }

    public init() {
        // TODO
        // @KeyValueCodableStorage("InventoryApp:defaults")
        data = .init()
    }
    
    var scanner: Scanner {
        get { data.scanner }
        set { data.scanner = newValue }
    }
}

extension Defaults {
    struct Data: Codable {
        var scanner = Scanner()
    }
    
    struct Scanner: Codable {
        var minPresenceTime: TimeInterval = BarcodeScanner.defaultMinPresenceTime
        var minAbsenceTime: TimeInterval = BarcodeScanner.defaultMinAbsenceTime
        
        var isDefault: Bool {
            minPresenceTime == BarcodeScanner.defaultMinPresenceTime &&
            minAbsenceTime == BarcodeScanner.defaultMinAbsenceTime
        }
        
        mutating func reset() {
            self = .init(
                minPresenceTime: BarcodeScanner.defaultMinPresenceTime,
                minAbsenceTime: BarcodeScanner.defaultMinAbsenceTime
            )
        }
    }
}
