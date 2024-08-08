//
//  SignInVM.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation

@MainActor
final class AuthenticationVM: ObservableObject {
    @Published var email: String = ""
    @Published var pwd: String = ""
}

// Sign in email functions
extension AuthenticationVM {
    func signUp() async throws {
        guard !email.isEmpty, !pwd.isEmpty else {
            // TODO: Create error logs.
            // TODO: Can add checks for valid email address here.
            print("No email or password found.")
            return
        }
        try await AuthenticationManager.shared.createUser(email: email, pwd: pwd)
    }
    func signIn() async throws {
        guard !email.isEmpty, !pwd.isEmpty else {
            print("No email or password found.")
            return
        }
        
        try await AuthenticationManager.shared.signInUser(email: email, pwd: pwd)
    }
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

// Sign in Google functions
extension AuthenticationVM {
    func signInGoogle() async throws {
        try await AuthenticationManager.shared.signInGoogle()
    }
}

// Miscellaneous functions
extension AuthenticationVM {
    func resetFields() {
        email = ""
        pwd = ""
    }
}
