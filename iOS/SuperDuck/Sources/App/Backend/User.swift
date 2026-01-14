import Foundation
import Supabase

typealias User = Supabase.User

extension User {
    var idString: String {
        id.uuidString.lowercased()
    }
}

extension User {
    public var firstName: String {
        userMetadata["first_name"]?.value as? String ?? ""
    }
    
    public var lastName: String {
        userMetadata["last_name"]?.value as? String ?? ""
    }
    
    public var name: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
