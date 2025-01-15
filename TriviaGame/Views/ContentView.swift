//
//  ContentView.swift
//  TriviaGame
//
//  Created by kuet on 8/11/23.
//

import SwiftUI
import Firebase

@MainActor
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State var email: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userExist = 0
    @State var invalidPass = 0
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var isActive: Bool = false
    @State private var goToSignUp: Bool = false
    
    @State private var showResetPassword = false
    @State private var resetEmail = ""
    @State private var resetMessage = ""
    @State private var showResetAlert = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ZStack {
                VStack {
                    VStack(spacing: 20) {
                        Text("Sign In")
                            .font(.largeTitle)
                            .bold()
                            .padding()
                            .foregroundColor(Color("AccentColor"))
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        Button(action: signIn) {
                            Text("Sign in")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: { showResetPassword = true }) {
                            Text("Forgot Password?")
                                .foregroundColor(Color("AccentColor"))
                        }
                        .sheet(isPresented: $showResetPassword) {
                            PasswordResetView(
                                email: $resetEmail,
                                message: $resetMessage,
                                showAlert: $showResetAlert,
                                isPresented: $showResetPassword
                            )
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        Text("Don't have account?")
                            .font(.title3)
                            .bold()
                            .foregroundColor(Color("AccentColor"))
                        
                        Button(action: { goToSignUp = true }) {
                            Text("Sign Up")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentColor"))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("Background"))
                
                if isActive {
                    Home()
                }
                
                if goToSignUp {
                    SignUp()
                }
            }
            .alert("Error", isPresented: $authManager.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "An error occurred")
            }
            .navigationDestination(isPresented: $goToSignUp) {
                SignUp()
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func signIn() {
        authManager.signIn(email: email, password: password) { success in
            // Handle any additional post-sign-in logic if needed
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(height: 50)
            .background(Color.black.opacity(0.05))
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
