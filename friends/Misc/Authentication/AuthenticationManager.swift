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
struct AuthDataResultModel {
    
    var uid: String
    var email: String?
    var photo_url: String?
    
    var username: String?
    var fullName: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photo_url = user.photoURL?.absoluteString
        // TODO: Make a view flow that asks for username and full name
        self.username = "Placeholder"
        self.fullName = ""
    }
    
    // TODO: Make separate initializers based on sign in method?
}

enum authProviderOption: String {
    case email = "password"
    case gmail = "google.com"
    case apple = "apple.com"
}

final class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}
    
    func getAuthenticatedUserData() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            print("GetAuthenticatedUserData() failed.")
            throw AuthError.noUserSignedIn
        }
        return AuthDataResultModel(user: user)
    }
    
    func getAuthenticatedUser() throws -> User {
        guard let user = Auth.auth().currentUser else {
            print("GetAuthenticatedUser() failed.")
            throw AuthError.noUserSignedIn
        }
        return user
    }
    
    func checkSignIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    // Special sign-in function for Google and Apple
    func signInWithCredential(credential: AuthCredential) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func getProviders() throws -> [authProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            throw AuthError.getProvidersFailed
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
    
    func updateProfilePictureURL(downloadURL: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noUserSignedIn
        }
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = URL(string: downloadURL)
        try await changeRequest.commitChanges()
    }
}

// MARK: Email functions
extension AuthenticationManager {
    @discardableResult
    func createUser(email: String, pwd: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: pwd)
        // TODO: Re-add this later.
//        try await authDataResult.user.sendEmailVerification()
        try Auth.auth().signOut()
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    @discardableResult
    func signInUser(email: String, pwd: String) async throws -> AuthDataResultModel {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: pwd)
        // TODO: Re-add this later.
//        guard authDataResult.user.isEmailVerified else {
//            try Auth.auth().signOut()
//            throw AuthError.authorizationFailed
//        }
        return AuthDataResultModel(user: authDataResult.user)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func updateEmail(newEmail: String, pwd: String) async throws {
        guard let user = Auth.auth().currentUser else {
            print("AuthenticationManager: No user signed in.")
            throw AuthError.noUserSignedIn
        }
        
        guard let email = user.email else {
            print("AuthenticationManager: User has no email.")
            throw AuthError.noUserSignedIn
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: pwd)
        
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            print("AuthenticationManager: Reauthentication failed.")
            throw AuthError.reauthenticationFailed
        }
        
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
        } catch {
            print("AuthenticationManager: Failed to update email.")
            throw AuthError.updateEmailFailed
        }
    }
    
    func updatePassword(email: String, pwd: String, pwdN: String) async throws {
        guard let user = Auth.auth().currentUser else {
            print("AuthenticationManager: No user signed in.")
            throw AuthError.noUserSignedIn
        }
        guard let email = user.email else {
            print("AuthenticationManager: User has no email.")
            throw AuthError.noUserSignedIn
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: pwd)
        
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            print("AuthenticationManager: Reauthentication failed.")
            throw AuthError.reauthenticationFailed
        }
        
        do {
            try await user.updatePassword(to: pwdN)
        } catch {
            print("AuthenticationManager: Failed to update email.")
            throw AuthError.updatePasswordFailed
        }
    }
}

// MARK: Other sign-in method functions
extension AuthenticationManager {
    @discardableResult
    func signInGoogle() async throws -> AuthDataResultModel {
        let googleSignInResult = try await SignInGoogleHelper().signIn()
        let credential = GoogleAuthProvider.credential(withIDToken: googleSignInResult.idToken,
                                                       accessToken: googleSignInResult.accessToken)
        return try await signInWithCredential(credential: credential)
    }
    @discardableResult
    func signInApple(signInAppleResult: SignInWithAppleResult) async throws -> AuthDataResultModel {
        let credential = OAuthProvider.credential(providerID: AuthProviderID.apple,
                                            idToken: signInAppleResult.token,
                                            rawNonce: signInAppleResult.nonce
                                            )
        return try await signInWithCredential(credential: credential)
    }
}

// MARK: Reauthenticate functions; needed for deleting users
extension AuthenticationManager {
    func deleteUser(authProviders: [authProviderOption]) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noUserSignedIn
        }
        if authProviders.contains(.apple) {
            let credential = try await SignInAppleHelper().getAppleCredential()
            try await user.reauthenticate(with: credential.0)
            try await Auth.auth().revokeToken(withAuthorizationCode: credential.1)
        }
        else if authProviders.contains(.gmail) {
            let credential = try await SignInGoogleHelper().getGoogleCredential()
            try await user.reauthenticate(with: credential)
        }
        try await user.delete()
    }
}
