//
//  AuthenticationManager.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation
import FirebaseAuth

// Sign-in Method: Email/Password
// adr = AuthDataResult
struct adr_model {
    let uid: String
    let email: String?
    let photo_url: String?
    
    //    let username: String?
    //    let name: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photo_url = user.photoURL?.absoluteString
    }
}

enum authProviderOption: String {
    case email = "password"
    case gmail = "google.com"
    case apple = "apple.com"
}

final class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}
    
    func getAuthenticatedUserData() throws -> adr_model {
        guard let user = Auth.auth().currentUser else {
            // TODO: Create custom throw error
            throw URLError(.badServerResponse)
        }
        return adr_model(user: user)
    }
    
    func getAuthenticatedUser() throws -> User {
        guard let user = Auth.auth().currentUser else {
            // TODO: Create custom throw error
            throw URLError(.badServerResponse)
        }
        return user
    }
    
    func checkSignIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    func signIn(credential: AuthCredential) async throws -> adr_model {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return adr_model(user: authDataResult.user)
    }
    
    func get_providers() throws -> [authProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            // TODO: Create error.
            throw URLError(.badServerResponse)
        }
        
        var providers: [authProviderOption] = []
        for provider in providerData {
            if let option = authProviderOption(rawValue: provider.providerID) {
                providers.append(option)
            } else {
                assertionFailure("Provider option not found: \(provider.providerID)")
            }
        }
        return providers
    }
}

// MARK: Email functions
extension AuthenticationManager {
    @discardableResult
    func createUser(email: String, pwd: String) async throws -> adr_model {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: pwd)
        return adr_model(user: authDataResult.user)
    }
    
    @discardableResult
    func signInUser(email: String, pwd: String) async throws -> adr_model {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: pwd)
        return adr_model(user: authDataResult.user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updateEmail(new_email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            // TODO: Create error.
            throw URLError(.badServerResponse)
        }
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: password)
        
        try await user.reauthenticate(with: credential)
        
        try await user.updateEmail(to: new_email)
    }
    
    func updatePassword(email: String, password: String, new_pass: String) async throws {
        guard let user = Auth.auth().currentUser else {
            // TODO: Create actual errors.
            throw URLError(.badServerResponse)
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
        
        try await user.updatePassword(to: new_pass)
    }
    
    func deleteUser() async throws {
        guard let user = Auth.auth().currentUser else {
            // TODO: Create actual errors.
            throw URLError(.badServerResponse)
        }
        try await user.delete()
    }
}

// MARK: Other sign-in method functions
extension AuthenticationManager {
    @discardableResult
    func signInGoogle() async throws -> adr_model {
        let tokens = try await SignInGoogleHelper().signIn()
        let credential = GoogleAuthProvider.credential(withIDToken: tokens.idToken, accessToken: tokens.accessToken)
        return try await signIn(credential: credential)
    }
}
