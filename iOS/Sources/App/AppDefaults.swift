import Foundation

@Observable
class AppDefaults {
    static let shared = AppDefaults()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
}
