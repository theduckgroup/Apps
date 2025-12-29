import Foundation
import CommonMacros

@attached(member, names: arbitrary)
public macro Cloneable() = #externalMacro(module: "CommonMacros", type: "ClonableMacro")
