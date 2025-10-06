import Foundation

struct User: Codable {
    var userId: String
    var username: String
    var profile: Profile
    var roles: [String]
    var appData: AppData
    
    struct Profile: Codable {
        var email: String
        var firstName: String
        var lastName: String
        
        var name: String {
            "\(firstName) \(lastName)"
        }
    }
    
    struct AppData: Codable {
        
    }
}

extension User {
    static let mock = User(
        userId: "123",
        username: "khanh",
        profile: .init(
            email: "khanh@gmail.com",
            firstName: "Khanh",
            lastName: "Nguyen"
        ),
        roles: ["org:admin"],
        appData: .init()
    )
}
