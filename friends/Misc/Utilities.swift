//
//  Utilities.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation
import UIKit

final class Utilities {
    
    static let shared = Utilities()
    private init () {}
    
    func is_valid_email(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        
        return emailPred.evaluate(with: email)
    }
    
    func is_valid_password(password: String) -> Bool {
        // At least 8 characters: ".{8,}"
        // At least one number: "(?=.*[0-9])"
        // At least one special character: "(?=.*[!@#$%^&*])"
        // At least one uppercase letter: "(?=.*[A-Z])"
        
        let password_test = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[0-9])(?=.*[!@#$%^&*])(?=.*[A-Z]).{8,}$")
        return password_test.evaluate(with: password)
    }
    
}
