//
//  UserProfileVM.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import Foundation

@MainActor
final class UserProfileVM: ObservableObject {
    @Published var auth_providers: [authProviderOption] = []
    @Published var string1: String = ""
    @Published var string2: String = ""
    
    func deleteUser() async throws {
        try await AuthenticationManager.shared.deleteUser()
    }
}

// MARK: Email functions
extension UserProfileVM {
    func resetPassword() async throws {
        let authUserData = try AuthenticationManager.shared.getAuthenticatedUserData()
        guard let email = authUserData.email else {
            // TODO: Create custom error for this.
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    // You can only call this function if they're not signed in with Apple or Google
    // TODO: Send email verification before updating information?
//    func updateEmail(newEmail: String, pwd: String) async throws {
//        guard let authUserData = try await AuthenticationManager.shared.getAuthenticatedUserData() else {return}
//        guard let email = authUserData.email else {return}
//        try await AuthenticationManager.shared.updateEmail(new_email: newEmail, password: pwd)
//    }
    // TODO: Send email verification before updating information?
//    func updatePassword(pwd: String, new_pwd: String) async throws {
//        guard let authUserData = try await AuthenticationManager.shared.getAuthenticatedUserData() else {
//            print("UserViewModel: Error updating password")
//            return
//        }
//        guard let email = authUserData.email else {return}
//        try await AuthenticationManager.shared.updatePassword(email: email, password: pwd, new_pass: new_pwd)
//    }
    
}

// MARK: Miscellaneous Functions
extension UserProfileVM {
    func resetFields() {
        string1 = ""
        string2 = ""
    }
}
