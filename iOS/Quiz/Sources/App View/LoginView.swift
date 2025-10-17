import Foundation
import SwiftUI
import Common

struct LoginView: View {
    @State var email: String = ""
    @State var password: String = ""
    @FocusState var emailFocused: Bool
    @State var loading = false
    @State var presentingError = false
    @State var error: String?
    @Environment(\.colorScheme) private var colorScheme
    
    init() {}
    
    var body: some View {
        VStack {
            loginView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .alert("Error", isPresented: $presentingError, presenting: error, actions: { _ in
            Button("OK") {}
        }, message: { error in
            Text("\(error)")
        })
        .onAppear {
            emailFocused = true
        }
    }
    
    @ViewBuilder
    private func loginView() -> some View {
        VStack(spacing: 15) {
            // Username + password
            
            VStack {
                InputField("Email", text: $email)
                    .focused($emailFocused)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                
                InputField("Password", text: $password, secure: true)
                    .submitLabel(.go)
                    .onSubmit {
                        Task {
                            await login()
                        }
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
                            .tint(.primary)
                        
                    } else {
                        Text("Log in")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 33)
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty)
        }
        .disabled(loading)
        .frame(width: 320)
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
            try await Auth.shared.signIn(email: email, password: password)
            
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
}
