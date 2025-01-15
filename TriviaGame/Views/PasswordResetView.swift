import SwiftUI
import Firebase

struct PasswordResetView: View {
    @Binding var email: String
    @Binding var message: String
    @Binding var showAlert: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color("AccentColor"))
                
                Text("Enter your email address to receive a password reset link")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.gray)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .autocapitalization(.none)
                
                Button(action: resetPassword) {
                    Text("Send Reset Link")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Password Reset"),
                    message: Text(message),
                    dismissButton: .default(Text("OK")) {
                        if message.contains("sent") {
                            isPresented = false
                        }
                    }
                )
            }
        }
    }
    
    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = error.localizedDescription
            } else {
                message = "Password reset link has been sent to your email"
            }
            showAlert = true
        }
    }
} 