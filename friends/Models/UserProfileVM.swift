//
//  UserProfileVM.swift
//  friends
//
//  Created by Bryan Hoang on 8/7/24.
//

import Foundation

@MainActor
final class UserProfileVM: ObservableObject {
    
    @Published var string1: String = ""
    @Published var string2: String = ""
    
    func deleteUser() async throws {
        try await AuthenticationManager.shared.deleteUser()
    }
}

// MARK: Email functions
extension UserProfileVM {
    func updateEmail(newEmail: String, pwd: String) async throws {
        try await AuthenticationManager.shared.updateEmail(newEmail: newEmail, pwd: pwd)
    }
    func updatePassword(email: String, pwd: String, pwdN: String) async throws {
        try await AuthenticationManager.shared.updatePassword(email: email, pwd: pwd, pwdN: pwdN)
    }
    func resetPassword() async throws {
        let authUserData = try AuthenticationManager.shared.getAuthenticatedUserData()
        guard let email = authUserData.email else {
            // TODO: Create custom error for this.
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
}

// MARK: Miscellaneous Functions
extension UserProfileVM {
    func resetFields() {
        string1 = ""
        string2 = ""
    }
}
