import Foundation
import SwiftUI

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""
    @FocusState var usernameFocused: Bool
    @State var loading = false
    @State var presentingSettings = false
    @State var presentingError = false
    @State var error: String?
    
    init() {}
    
    var body: some View {
        VStack {
            loginView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("Settings") {
                presentingSettings = true
            }
        }
        .padding()
        .sheet(isPresented: $presentingSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: $presentingError, presenting: error, actions: { _ in
            Button("OK") {}
        }, message: { error in
            Text("\(error)")
        })
        .onAppear {
            usernameFocused = true
        }
    }
    
    @ViewBuilder
    private func loginView() -> some View {
        VStack(spacing: 15) {
            // Username + password
            
            VStack {
                InputField("Email", text: $username)
                    .focused($usernameFocused)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                InputField("Password", text: $password, secure: true)
                    .onKeyPress(.return) {
                        guard !username.isEmpty && !password.isEmpty else {
                            return .ignored
                        }
                        
                        Task {
                            await login()
                        }
                        
                        return .handled
                    }
            }
            
            // Login button
            
            Button {
                Task {
                    await login()
                }
                
            } label: {
                Group {
                    if loading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        
                    } else {
                        Text("Log in")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 30)
            }
            .buttonStyle(.borderedProminent)
        }
        .disabled(loading)
        .frame(width: 250)
    }
    
    private func login() async {
        loading = true
        
        defer {
            loading = false
        }
        
        if isRunningForPreviews {
            try! await Task.sleep(for: .seconds(2))
            return
        }
        
        do {
            try await Task.sleep(for: .seconds(0.5))
            try await UserManager.shared.login(username: username, password: password)
            
        } catch {
            self.error = formatError(error)
            presentingError = true
        }
    }
}

private struct InputField: View {
    var titleKey: LocalizedStringKey
    @Binding var text: String
    var secure: Bool
    
    init(_ titleKey: LocalizedStringKey, text: Binding<String>, secure: Bool = false) {
        self.titleKey = titleKey
        self._text = text
        self.secure = secure
    }
    
    var body: some View {
        Group {
            if secure {
                SecureField(titleKey, text: $text)
                
            } else {
                TextField(titleKey, text: $text)
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal)
        .background(Color.gray.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}
