import Foundation
public import SwiftUI

public struct BarcodeScannerSettingsView: View {
    @Environment(InventoryAppDefaults.self) var defaults
    @State var showsMinPresenceTimeInfo = true
    @State var showsMinAbsenceTimeInfo = true
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    public init() {}
    
    public var body: some View {
        Form {
            Section("QR Code Scanner") {
                bodyContent()
            }
        }
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        @Bindable var defaults = defaults
        let compact = horizontalSizeClass == .compact
        
        VStack(alignment: .leading) {
            Text("These settings control the QR code scanner sensitivity.")
                .padding(.bottom, 9)
            
            let sliderView = {
                let binding = $defaults.scanner.minPresenceTime
                let formattedValue = (binding.wrappedValue * 1000).formatted(.number) + " ms"
                
                return HStack {
                    Slider(value: binding, in: 0.025...1, step: 0.025)
                    Text(formattedValue).monospacedDigit()
                }
            }()
            
            HStack(alignment: .center) {
                Text("Min Presence Time")
                
//                Button {
//                    showsMinPresenceTimeInfo.toggle()
//                    
//                } label: {
//                    Image(systemName: "info.circle")
//                }
//                .buttonStyle(.borderless)
                
                if !compact {
                    Spacer()
                    sliderView
                        .frame(width: 350)
                }
            }
            .frame(minHeight: compact ? nil : 42)
            
            if showsMinPresenceTimeInfo {
                Text(
                    """
                    The amount of time a code must stay in the camera feed before it is recognized.
                    """
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
            }
            
            if compact {
                sliderView
            }
        }
        
        VStack(alignment: .leading) {
            let sliderView = {
                let binding = $defaults.scanner.minAbsenceTime
                let formattedValue = (binding.wrappedValue * 1000).formatted(.number) + " ms"
                
                return HStack {
                    Slider(value: binding, in: 0.1...1, step: 0.025)
                    Text(formattedValue).monospacedDigit()
                }
            }()
            
            HStack {
                Text("Min Duplicate Absence Time")
                
//                Button {
//                    showsMinAbsenceTimeInfo.toggle()
//                    
//                } label: {
//                    Image(systemName: "info.circle")
//                }
//                .buttonStyle(.borderless)
                
                if !compact {
                    Spacer()
                    sliderView
                        .frame(width: 350)
                }
            }
            .frame(minHeight: compact ? nil : 42)
            
            if showsMinAbsenceTimeInfo {
                Text(
                    """
                    The amount of time a QR code must be absent from camera feed before it is \
                    recognized again. Increase this if the scanner recognizes the same code \
                    multiple times (most likely on slow devices).
                    """
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 1)
            }
            
            if compact {
                sliderView
            }
        }
        
        Button("Reset to Default") {
            defaults.scanner = .init()
        }
        .disabled(defaults.scanner == InventoryAppDefaults.Scanner())
        .buttonStyle(.borderless)
    }
}


#Preview {
    NavigationStack {
        BarcodeScannerSettingsView()
            .previewEnvironment()
    }
}
