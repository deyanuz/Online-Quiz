//
//  AuthManager.swift
//  TriviaGame
//
//  Created by Gaming Lab on 9/1/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    init() {
        // Check if a user is logged in when the app starts
        self.currentUser = Auth.auth().currentUser
        self.isLoggedIn = currentUser != nil
    }
    
    func signUp(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.showError = true
                completion(false)
            } else if let user = result?.user {
                self?.currentUser = user
                self?.isLoggedIn = true
                completion(true)
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                self?.showError = true
                completion(false)
            } else if let user = result?.user {
                self?.currentUser = user
                self?.isLoggedIn = true
                completion(true)
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
