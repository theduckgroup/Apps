import Foundation
import SwiftUI

struct SettingsView: View {
    @State var presentingConfirmResetDataAlert = false
    @State var presentingConfirmLogoutAlert = false
    @State var userManager = UserManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    
    init() {}
    
    var body: some View {
        NavigationStack {
            List {
                bodyContent()
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isPresented {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
            }
        }
        .onAppear {
            Task {
                try await userManager.refreshUser()
            }
        }
    }
    
    private var user: User? {
        userManager.user
    }
    
    @ViewBuilder
    private func bodyContent() -> some View {
        if let user {
            Section("Account") {
                HStack(alignment: .center) {
//                    Image(systemName: "person.circle")
//                        // .symbolVariant(.fill)
//                        .imageScale(.large)
//                        .font(.system(size: 48, weight: .thin))
//                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading) {
                        Text(user.profile.name)
                            .font(.title)
                        
                        Text(user.profile.email)
                    }
                }
                
                Button("Log out") {
                    presentingConfirmLogoutAlert = true
                }
                .buttonStyle(.borderless)
                .alert("Log out?", isPresented: $presentingConfirmLogoutAlert) {
                    Button("Log out") {
                        Task {
                            await userManager.logout()
                        }
                    }
                    
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        
        Section("Scanner Settings") {
            ScannerSettingsView()
        }
        
        Section("App Info") {
//            Button("Reset Data") {
//                presentingConfirmResetDataAlert = true
//            }
//            .alert("Reset Data?", isPresented: $presentingConfirmResetDataAlert) {
//                Button("Reset", role: .destructive) {
//                    userManager.resetData()
//                }
//                
//                Button("Cancel", role: .cancel) {}
//            }
            
            Text("Version: \(AppInfo.bundleVersion)")
        }
    }
}

private struct ScannerSettingsView: View {
    @Environment(AppDefaults.self) var appDefaults
    @State var showsMinPresenceTimeInfo = false
    @State var showsMinAbsenceTimeInfo = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        @Bindable var appDefaults = appDefaults
        let compact = horizontalSizeClass == .compact
        
        VStack(alignment: .leading) {
            let sliderView = {
                let binding = $appDefaults.scanner.minPresenceTime
                let formattedValue = binding.wrappedValue.formatted(.number.precision(.fractionLength(2))) + " sec"
                
                return HStack {
                    Slider(value: binding, in: 0.1...1, step: 0.050)
                    Text(formattedValue).monospacedDigit()
                }
            }()
            
            HStack(alignment: .center) {
                Text("Minimum Presence Time")
                
                Button {
                    showsMinPresenceTimeInfo.toggle()
                    
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                
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
                    The amount of time a code must stay in the camera feed before it is recognized. \
                    Lower values mean faster scanning but more room for mistakes.
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
                let binding = $appDefaults.scanner.minAbsenceTime
                let formattedValue = binding.wrappedValue.formatted(.number.precision(.fractionLength(2))) + " sec"
                
                return HStack {
                    Slider(value: binding, in: 0.1...1, step: 0.050)
                    Text(formattedValue).monospacedDigit()
                }
            }()
            
            HStack {
                Text("Minimum Duplicate Absence Time")
                
                Button {
                    showsMinAbsenceTimeInfo.toggle()
                    
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.borderless)
                
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
        
        Button("Restore Defaults") {
            appDefaults.scanner.restoreDefaults()
        }
        .disabled(appDefaults.scanner.isDefault)
        .buttonStyle(.borderless)
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(AppDefaults.shared)
}
