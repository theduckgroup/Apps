import Foundation
import Auth

extension User {
    static let mock = User(
        id: UUID(),
        appMetadata: [:],
        userMetadata: [
            "first_name": "The Duck Group App",
            "last_name": ""
        ],
        aud: "",
        email: "theduckgroupapp@gmail.com",
        createdAt: Date(),
        updatedAt: Date(),
    )
}
