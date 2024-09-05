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
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        
        let controller = controller ?? UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.last?.rootViewController
        
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
    
    func generateTestUIImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Gradient background
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [UIColor.red.cgColor, UIColor.blue.cgColor] as CFArray,
                                      locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])
            
            // Add some text overlay
            let text = "Test Image"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 40),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                  y: (size.height - textSize.height) / 2,
                                  width: textSize.width,
                                  height: textSize.height)
            
            text.draw(in: textRect, withAttributes: textAttributes)
        }
        
        return image
    }

}
