import Foundation
import SwiftUI
import CommonUI

struct QuantityInputAlert: View {
    var title: String
    var subtitle: String
    @State var value: Int = 0
    @FocusState var isFocused: Bool
    var onCancel: () -> Void
    var onDone: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Text(title)
                    .bold()
                
                Text(subtitle)
            }
            
            let valueBinding = Binding<Double> {
                Double(value)
            } set: {
                value = Int($0.rounded())
            }
            
            QuantityField(value: valueBinding)
                .font(.system(size: 18))
                .focused($isFocused)
            
            HStack {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                }
                .modified {
                    if #available(iOS 26, *) {
                        $0.buttonStyle(.glass)
                    } else {
                        $0.buttonStyle(.bordered)
                    }
                }
                
                Button {
                    onDone(value)
                } label: {
                    Text("Done")
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                }
                .disabled(value == 0)
                .modified {
                    if #available(iOS 26, *) {
                        $0.buttonStyle(.glassProminent)
                    } else {
                        $0.buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
        .frame(width: 280)
        .ignoresSafeArea()
        .onFirstAppear {
            isFocused = true
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var ps = PresentationState()

        var body: some View {
            Button("Present") {
                present()
            }
            .presentations(ps)
        }

        func present() {
            ps.presentAlertStyleCover {
                QuantityInputAlert(
                    title: "Herbal Jelly 000",
                    subtitle: "BD123123",
                    onCancel: {
                        ps.dismiss()
                    },
                    onDone: { value in
                        ps.dismiss()
                    }
                )
            }
        }
    }
    
    return PreviewView()
}
