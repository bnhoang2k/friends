//
//  Errors.swift
//  friends
//
//  Created by Bryan Hoang on 8/14/24.
//

import Foundation

enum AuthError: Error {
    case noUserSignedIn
    case reauthenticationFailed
    case updateEmailFailed
    case updatePasswordFailed
}
