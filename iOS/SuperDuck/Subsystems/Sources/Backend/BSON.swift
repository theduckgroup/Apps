import Foundation
@_exported import SwiftBSON

// This does not work because `BSONObjectID.init()` seems to be defined outside the type
// public typealias BSONObjectID = SwiftBSON.BSONObjectID

public typealias ObjectID = BSONObjectID

extension ObjectID: @retroactive @unchecked Sendable {}
