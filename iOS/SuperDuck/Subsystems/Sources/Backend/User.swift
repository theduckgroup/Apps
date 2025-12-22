import Foundation
public import Supabase

public typealias User = Supabase.User

public extension User {
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
