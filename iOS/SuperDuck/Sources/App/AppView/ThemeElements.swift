import Foundation

@MainActor
struct MyStruct {
    var property1: MyClass /* Project class name */ = .init()
    var property2: MyOtherStruct /* Project type name */ = .init()
    var property3 /* Other declaration */: Int /* Other type name*/ = 0
    var property4: NSObject /* Other class name */ = .init()
    
    init /* Keyword */ () {}
    
    mutating func hello /* Other declaration */ (param1: String, param2: MyClass) {
        let _ /* Plain text */ = 102 /* Number */
        var var1 = "Hello"
        let var2 = 100
        let var3: Character = "a"
        
        self.walk/* Project function and method names */(speed /* Other properties and globals */: 100)
        self.walk(speed: 100)
        
        self.property1 /* Project properties and globals */ = .init()
        property1 = .init()
        var1 /* Plain text */ = "Yay"
        print(var1)
        
        let property1 = MyClass()
        print(property1)
    }
    
    func walk(speed: Double) {}
}

struct MyOtherStruct {
    #if DEBUG
    func eat() {}
    #else
    func drink() {}
    #endif
}

class MyClass {}
