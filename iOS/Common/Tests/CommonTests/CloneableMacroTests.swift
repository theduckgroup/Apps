import Foundation
import Testing
import Common

@Suite("Cloneable Macro")
struct CloneableMacroTests {
    @Test
    func `Basic Tests`() {
        @Cloneable
        class Data {
            
        }
    }
}
