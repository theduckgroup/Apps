import Foundation
import SwiftUI
import CommonUI

struct QuantityInputAlert: View {
    @State var value: Int = 0
    @FocusState var isFocused: Bool
    var onCancel: () -> Void
    var onDone: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            let valueBinding = Binding<Double> {
                Double(value)
            } set: {
                value = Int($0.rounded())
            }
            
            QuantityField(value: valueBinding)
                .focused($isFocused)
            
            HStack {
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
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
                        .frame(maxWidth: .infinity)
                }
                .modified {
                    if #available(iOS 26, *) {
                        $0.buttonStyle(.glassProminent)
                    } else {
                        $0.buttonStyle(.bordered)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .padding(.horizontal, 0)
        .padding(.top, 12)
        .padding(.bottom, 0)
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
            .onFirstAppear {
                present()
            }
        }

        func present() {
            ps.presentAlertCover(title: "Quantity", actions: []) {
                QuantityInputAlert(
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
