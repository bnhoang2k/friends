//
//  Errors.swift
//  friends
//
//  Created by Bryan Hoang on 8/14/24.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case noUserSignedIn
    case reauthenticationFailed
    case updateEmailFailed
    case updatePasswordFailed
    case updateFNFailed
    case updateUsernameFailed
    case noDisplayNameFound
    case getProvidersFailed
    case parametersNULL
    case deleteUserFailed
    
    // Google and Apple
    case findVCFailed
    case findTokenFailed
    
    // Apple
    case authorizationFailed
    
    var errorDescription: String? {
        switch self {
        case .noUserSignedIn:
            return NSLocalizedString("No user is currently signed in.",
                                     comment: "Auth Error - No User.")
        case .reauthenticationFailed:
            return NSLocalizedString("Re-authentication failed.",
                                     comment: "Auth Error - Reauthentication failed.")
        case .updateEmailFailed:
            return NSLocalizedString("Failed to update email.",
                                     comment: "Auth Error - Update email failed.")
        case .updatePasswordFailed:
            return NSLocalizedString("Failed to update poassword.",
                                     comment: "Auth Error - Update password failed.")
        case .updateFNFailed:
            return NSLocalizedString("Failed to update full name.",
                                     comment: "Auth Error - Update full name failed.")
        case .updateUsernameFailed:
            return NSLocalizedString("Failed to update username.",
                                     comment: "Auth Error - Update username failed.")
        case .noDisplayNameFound:
            return NSLocalizedString("Failed to a display name.",
                                     comment: "Auth Error - No display name found.")
        case .getProvidersFailed:
            return NSLocalizedString("Failed to get providers.",
                                     comment: "Auth Error - Failed to get providers.")
        case .parametersNULL:
            return NSLocalizedString("Parameters needed are null.",
                                     comment: "Auth Error - Parameters are null.")
        case .deleteUserFailed:
            return NSLocalizedString("Failed to delete user.",
                                     comment: "Auth Error - Delete user failed.")
        case .findVCFailed:
            return NSLocalizedString("Top VC cannot be found.",
                                     comment: "Auth Error - Refer to SignInGoogleHelper.")
        case .findTokenFailed:
            return NSLocalizedString("Failed to find the ID token for sign in.",
                                     comment: "Auth Error - Failed to find ID tokens for sign in.")
        case .authorizationFailed:
            return NSLocalizedString("Authorization controller failed.",
                                     comment: "Auth Error - Refer to AppleSignInHelper.")
        }
    }
    
    // MARK: Optional variables; follows the same switch case format as above.
//    var failureReason: String? {}
//    var recoverySuggestion: String? {}
//    var helpAnchor: String? {}
}
