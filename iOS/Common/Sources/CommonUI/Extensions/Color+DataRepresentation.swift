import Foundation
import SwiftUI
import Common

public struct ColorData: Codable {
    public var data: Data
    
    public init(_ color: Color) {
        self.data = color.data()
    }

    public var color: Color {
        do {
            return try Color(data: data)
            
        } catch {
            assertionFailure()
            return .black
        }
    }
}

extension Color {
    public init(data: Data) throws {
        guard let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            assertionFailure()
            throw GenericError("Nil color")
        }
        
        self = Color(color)
    }

    public func data() -> Data {
        let data = try! NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false)
        return data
    }
}
