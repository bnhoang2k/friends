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

// MARK: Sign in email functions
extension AuthenticationVM {
    func signUp() async throws {
        guard !email.isEmpty, !pwd.isEmpty else {
            // TODO: Create error logs.
            // TODO: Can add checks for valid email address here.
            print("No email or password found.")
            return
        }
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, pwd: pwd)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
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

// MARK: Sign in other methods
extension AuthenticationVM {
    func signInGoogle() async throws {
        let authDataResult = try await AuthenticationManager.shared.signInGoogle()
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    func signInApple() async throws {
        let helper = SignInAppleHelper()
        let tokens = try await helper.signInApple()
        let authDataResult = try await AuthenticationManager.shared.signInApple(tokens: tokens)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
}

// MARK: Miscellaneous functions
extension AuthenticationVM {
    func resetFields() {
        email = ""
        pwd = ""
    }
}
