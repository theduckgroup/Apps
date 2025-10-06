import Foundation
import SwiftUI

/// View that shows the "Add Items" and "Remove Items" buttons.
struct ScanLaunchView: View {
    @State var presentedScanViewScanMode: ScanMode?
    @State var inventoryStore = InventoryStore.shared
    
    init() {}
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .imageScale(.large)
                    .font(.system(size: 105, weight: .light))
                
                HStack(spacing: 15) {
                    Button("Add Items", systemImage: "plus.circle") {
                        presentedScanViewScanMode = .add
                    }
                    
                    Button("Sell Items", systemImage: "minus.circle") {
                        presentedScanViewScanMode = .subtract
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inventoryStore.selectedVendor == nil)
            }
        }
        .fullScreenCover(item: $presentedScanViewScanMode) { scanMode in
            let vendor = inventoryStore.selectedVendor!
            ScanView(vendor: vendor, scanMode: scanMode)
        }
    }
}

#Preview {
    ScanLaunchView()
        .preferredColorScheme(.dark)
}
