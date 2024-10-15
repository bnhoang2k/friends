//
//  AppleSignInHelper.swift
//  friends
//
//  Created by Bryan Hoang on 8/9/24.
//

import Foundation
import SwiftUI
import CryptoKit
import AuthenticationServices
import FirebaseAuth

struct SignInWithAppleResult {
    let token: String
    let nonce: String
    let name: String?
    let email: String?
    let authorizationCodeString: String?
}

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        ASAuthorizationAppleIDButton(authorizationButtonType: type,
                                     authorizationButtonStyle: style)
    }
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
    }
}

@MainActor
final class SignInAppleHelper: NSObject {
    
    // Unhashed nonce.
    private var currentNonce: String?
    
    private var completionHandler: ((Result<SignInWithAppleResult, Error>) -> Void)? = nil
    
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the set, wrapping around if needed.
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    @available(iOS 13, *)
    func startSignInWithAppleFlow(completion: @escaping(Result<SignInWithAppleResult, Error>) -> Void) {
        
        guard let topVC = Utilities.shared.topViewController() else {
            completion(.failure(AuthError.findVCFailed))
            return
        }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        completionHandler = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = topVC
        authorizationController.performRequests()
    }
    
    func signInApple() async throws -> SignInWithAppleResult {
        try await withCheckedThrowingContinuation { continuation in
            self.startSignInWithAppleFlow { result in
                switch result {
                case .success(let signInAppleResult):
                    continuation.resume(returning: signInAppleResult)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

@available(iOS 13.0, *)
extension SignInAppleHelper: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idToken = String(data: appleIDToken, encoding: .utf8),
              let nonce = currentNonce else {
            completionHandler?(.failure(AuthError.findTokenFailed))
            print("AuthorizationController Error: Tokens")
            return
        }
        
        var name: String = ""
        if let fullName = appleIDCredential.fullName {
            let givenName = fullName.givenName ?? ""
            let familyName = fullName.familyName ?? ""
            name = "\(givenName) \(familyName)"
        }
        let email = appleIDCredential.email
        guard let authorizationCode = appleIDCredential.authorizationCode else {return}
        guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else {return}
        let appleSignInResult = SignInWithAppleResult(token: idToken,
                                                      nonce: nonce,
                                                      name: name,
                                                      email: email,
                                                      authorizationCodeString: authCodeString)
        
        completionHandler?(.success(appleSignInResult))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completionHandler?(.failure(AuthError.authorizationFailed))
        print("Sign in with Apple errored: \(error)")
    }
}

extension SignInAppleHelper {
    func getAppleCredential() async throws -> (AuthCredential, String) {
        let signInAppleResult = try await signInApple()
        
        let credential = OAuthProvider.credential(withProviderID: authProviderOption.apple.rawValue,
                                                  idToken: signInAppleResult.token,
                                                  rawNonce: signInAppleResult.nonce)
        guard let authorizationCodeString: String = signInAppleResult.authorizationCodeString else {
            throw AuthError.authorizationFailed
        }
        return (credential, authorizationCodeString)
    }
}

extension UIViewController: @retroactive ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

