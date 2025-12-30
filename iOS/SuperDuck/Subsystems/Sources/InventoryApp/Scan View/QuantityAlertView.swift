import Foundation
import SwiftUI

struct QuantityAlertView: View {
    @State var value: String
    var onCancel: () -> Void
    var onDone: (Int) -> Void
    
    var body: some View {
        VStack {
            Text("Enter quantity")
            
            TextField("", text: $value)
            
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                
                Button("Done") {
                    onDone(Int(value) ?? 0)
                }
            }
        }
    }
}
