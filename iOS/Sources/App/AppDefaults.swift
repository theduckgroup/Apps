import Foundation

@Observable
class AppDefaults {
    static let shared = AppDefaults()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        scanner = .init(
            minPresenceTime: userDefaults.value(forKey: "Scanner:minPresenceTime") as? Double ?? BarcodeScanner.defaultMinPresenceTime,
            minAbsenceTime: userDefaults.value(forKey: "Scanner:minAbsenceTime") as? Double ?? BarcodeScanner.defaultMinAbsenceTime
        )
    }
    
    var scanner: Scanner {
        didSet {
            userDefaults.set(scanner.minPresenceTime, forKey: "Scanner:minPresenceTime")
            userDefaults.set(scanner.minAbsenceTime, forKey: "Scanner:minAbsenceTime")
        }
    }
}

extension AppDefaults {
    struct Scanner {
        var minPresenceTime: TimeInterval
        var minAbsenceTime: TimeInterval
        
        var isDefault: Bool {
            minPresenceTime == BarcodeScanner.defaultMinPresenceTime &&
            minAbsenceTime == BarcodeScanner.defaultMinAbsenceTime
        }
        
        mutating func restoreDefaults() {
            self = .init(
                minPresenceTime: BarcodeScanner.defaultMinPresenceTime,
                minAbsenceTime: BarcodeScanner.defaultMinAbsenceTime
            )
        }
    }
}
