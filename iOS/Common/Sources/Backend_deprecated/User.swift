import Foundation
import Supabase

public typealias User = Supabase.User

public extension User {
    var idString: String {
        id.uuidString.lowercased()
    }
}

public extension User {
    static let mock = User(
       id: UUID(),
       appMetadata: [:],
       userMetadata: [:],
       aud: "",
       createdAt: Date(),
       updatedAt: Date()
   )
}
