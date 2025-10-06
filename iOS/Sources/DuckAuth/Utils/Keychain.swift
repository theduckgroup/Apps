import Foundation
import Security

struct Keychain {
    private static let service = Bundle.main.bundleIdentifier!
    
    /// Saves a string value or updates it if it already exists.
    static func setValue(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        setValue(data, forKey: key)
    }
    
    /// Saves a data value or updates it if it already exists.
    static func setValue(_ value: Data, forKey key: String) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        
        query[kSecValueData as String] = value
        
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        
        switch addStatus {
        case errSecSuccess:
            return
            
        case errSecDuplicateItem:
            // Item already exists, try to update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            
            let attributesToUpdate: [String: Any] = [kSecValueData as String: value]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            
            guard updateStatus == errSecSuccess else {
                assertionFailure("Unexpected status \(addStatus)")
                return
            }
            
            return
            
        default:
            assertionFailure("Unexpected status \(addStatus)")
        }
    }

    /// Reads a string value.
    static func stringValueForKey(_ key: String) -> String? {
        guard let data = dataValueForKey(key) else {
            return nil
        }
        
        guard let value = String(data: data, encoding: .utf8) else {
            assertionFailure()
            return nil
        }
        
        return value
    }
    
    /// Reads a string value.
    static func dataValueForKey(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let value = result as? Data else {
                assertionFailure("Should not happen")
                return nil
            }
                        
            return value
            
        case errSecItemNotFound:
            return nil
            
        default:
            assertionFailure("Unexpected status \(status)")
            return nil
        }
    }
    
    /// Deletes a value.
    static func removeValueForKey(_ key: String) {
        // Define the query for the item to delete
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            return
            
        case errSecItemNotFound:
            return
            
        default:
            assertionFailure("Unexpected status \(status)")
        }
    }
    
    static func removeAll() {
        let secItemClasses = [kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity]
        
        for secItemClass in secItemClasses {
            let dictionary = [kSecClass as String:secItemClass]
            let status = SecItemDelete(dictionary as CFDictionary)
            
            if status != errSecSuccess && status != errSecItemNotFound {
                assertionFailure("Unexpected status \(status)")
            }
        }
    }
}

enum KeychainError: Error {
    case status(OSStatus)
    case dataConversionError
}
