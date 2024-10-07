//
//  SignInVM.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation

@MainActor
final class AuthenticationVM: ObservableObject {
    
    @Published var showSignInView: Bool = true
    @Published var showGetInformationView: Bool = false
    
    @Published var email: String = ""
    @Published var pwd: String = ""
    
    @Published private(set) var user: DBUser? = nil
    @Published var authProviders: [authProviderOption] = []
    
    func loadCurrentUser() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUserData()
        self.user = try await UserManager.shared.getUser(uid: authDataResult.uid)
    }
    
    func loadCurrentUser(newUser: DBUser) async throws {
        self.user = newUser
    }
    
    func getAuthProviders() {
        if let providers = try? AuthenticationManager.shared.getProviders() {
            authProviders = providers
        }
    }
    
    func handlePostSignIn() async throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUser()
        let userExists = try await UserManager.shared.doesUserExist(uid: user.uid)
        if userExists {
            showSignInView = false
            showGetInformationView = false
        }
        else {
            showSignInView = false
            showGetInformationView = true
        }
    }
    
    // Fills in misc. data
    func setUpProfile(username: String, fullName: String) async throws {
        var authDataResult = try AuthenticationManager.shared.getAuthenticatedUserData()
        authDataResult.fullName = fullName
        authDataResult.username = username
        // Default picture
        authDataResult.photo_url = "https://static-00.iconduck.com/assets.00/profile-default-icon-2048x2045-u3j7s5nj.png"
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
    func deleteUser() async throws {
        try await AuthenticationManager.shared.deleteUser(authProviders: authProviders)
    }
    
    func updateUserProfileURLInFirestore(downloadURL: String) async throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUserData()
        try await UserManager.shared.updateUserProfileImageURL(uid: user.uid, downloadURL: downloadURL)
    }
    
    func saveUserProfileChanges(dummyUser: DBUser, imageData: Data) async throws {
        let uid = try AuthenticationManager.shared.getAuthenticatedUserData().uid
        do {
            let downloadURL = try await UserManager.shared.uploadProfileImage(uid: uid, imageData: imageData)
            try await updateUserProfileURLInFirestore(downloadURL: downloadURL)
            try await UserManager.shared.updateUser(user!, with: dummyUser)
            try await loadCurrentUser(newUser: dummyUser)
        } catch {
            print("Error saving user profile changes.")
        }
    }
}

// MARK: Sign in email functions
extension AuthenticationVM {
    func signUp() async throws {
        guard !email.isEmpty, !pwd.isEmpty else {
            throw AuthError.parametersNULL
        }
        try await AuthenticationManager.shared.createUser(email: email, pwd: pwd)
    }
    
    func signIn() async throws {
        guard !email.isEmpty, !pwd.isEmpty else {
            throw AuthError.parametersNULL
        }
        try await AuthenticationManager.shared.signInUser(email: email, pwd: pwd)
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func updateEmail(newEmail: String, pwd: String) async throws {
        try await AuthenticationManager.shared.updateEmail(newEmail: newEmail, pwd: pwd)
        guard let newUser = user?.updateEmail(newEmail: newEmail) else {
            throw AuthError.updateEmailFailed
        }
        try await UserManager.shared.updateEmail(user: newUser)
    }
    
    func updatePassword(email: String, pwd: String, pwdN: String) async throws {
        try await AuthenticationManager.shared.updatePassword(email: email, pwd: pwd, pwdN: pwdN)
    }
    
    func resetPassword() async throws {
        let authUserData = try AuthenticationManager.shared.getAuthenticatedUserData()
        guard let email = authUserData.email else {
            throw AuthError.parametersNULL
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
}

// MARK: Updating user information
extension AuthenticationVM {
    func updateUsername(newUsername: String) async throws {
        guard let newUser = user?.updateUsername(newUsername: newUsername) else {
            throw AuthError.updateUsernameFailed
        }
        try await UserManager.shared.updateUsername(user: newUser)
    }
    
    func updateFName(newFN: String) async throws {
        guard let newUser = user?.updateFN(newFN: newFN) else {
            throw AuthError.updateFNFailed
        }
        try await UserManager.shared.updateFN(user: newUser)
    }
}

// MARK: Sign in other methods
extension AuthenticationVM {
    func signInGoogle() async throws {
        try await AuthenticationManager.shared.signInGoogle()
    }
    
    func signInApple() async throws {
        let helper = SignInAppleHelper()
        let appleSignInResult = try await helper.signInApple()
        try await AuthenticationManager.shared.signInApple(signInAppleResult: appleSignInResult)
    }
}

// MARK: Miscellaneous functions
extension AuthenticationVM {
    func resetFields() {
        email = ""
        pwd = ""
        user = nil
        authProviders = []
    }
}
