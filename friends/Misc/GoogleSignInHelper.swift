//
//  GoogleSignInHelper.swift
//  		
//
//  Created by Bryan Hoang on 8/8/24.
//  Created to de-couple to GoogleSignIn SDK from the rest of the project.

import Foundation
import GoogleSignIn
import GoogleSignInSwift

struct GoogleSignInResultModel {
    let idToken: String
    let accessToken: String
    let name: String?
    let email: String?
}

final class SignInGoogleHelper {
    
    @MainActor
    func signIn() async throws -> GoogleSignInResultModel {
        guard let topVC = Utilities.shared.topViewController() else {
            // TODO: Make an actual error here.
            throw URLError(.cannotFindHost)
        }
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            // TODO: Make an actual error here.
            throw URLError(.cannotFindHost)
        }
        let accessToken = gidSignInResult.user.accessToken.tokenString
        // TODO: Do we want to store the name and email in the tokens? or put them somewhere else to access within the view a lot easier?
        let name = gidSignInResult.user.profile?.name
        let email = gidSignInResult.user.profile?.email
        let tokens = GoogleSignInResultModel(idToken: idToken,
                                             accessToken: accessToken,
                                             name: name,
                                             email: email)
        return tokens
    }
}
