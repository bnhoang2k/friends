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
}

final class SignInGoogleHelper {
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        
        let controller = controller ?? UIApplication.shared.keyWindow?.rootViewController
        
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
    @MainActor
    func signIn() async throws -> GoogleSignInResultModel {
        guard let topVC = await SignInGoogleHelper().topViewController() else {
            // TODO: Make an actual error here.
            throw URLError(.cannotFindHost)
        }
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            // TODO: Make an actual error here.
            throw URLError(.cannotFindHost)
        }
        let accessToken = gidSignInResult.user.accessToken.tokenString
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken)
        return tokens
    }
}
