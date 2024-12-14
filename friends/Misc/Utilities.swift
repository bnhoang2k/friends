//
//  Utilities.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation
import SwiftUI

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
    
    func generateRandomHangouts(count: Int = 100) -> [Hangout] {
        var randomHangouts: [Hangout] = []
        
        let sampleTitles = ["Beach Party", "Movie Night", "Game Day", "Study Session", "Book Club"]
        let sampleDescriptions = ["Relaxing by the shore", "Watching the latest blockbusters", "Playing board games", "Studying for finals together", "Discussing our favorite novels"]
        let sampleTags = ["fun", "outdoor", "casual", "group", "budget-friendly"]
        let sampleLocations = ["Park", "Cinema", "Friend's House", "Cafe", "Library"]
        let sampleParticipantIds = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8"],
            ["9", "10", "11", "12"],
            ["13"]
        ]
        let sampleDurations: [HangoutDuration] = [.quick, .halfDay, .fullDay, .overnight]
        let sampleVibes: [HangoutVibe] = [.adventurous, .calm, .chill , .energetic , .exciting ,.relaxing, .social, .wild]
        let sampleStatuses: [HangoutStatus] = [.pending, .confirmed, .cancelled, .completed]
        
        for _ in 0..<count {
            let randomTitle = sampleTitles.randomElement()
            let randomDescription = sampleDescriptions.randomElement()
            let randomTags = sampleTags.shuffled().prefix(Int.random(in: 1...3))
            let randomLocation = sampleLocations.randomElement()
            let randomParticipants = sampleParticipantIds.randomElement() ?? []
            let randomDuration = sampleDurations.randomElement() ?? .quick
            let randomVibe = sampleVibes.randomElement() ?? .chill
            let randomStatus = sampleStatuses.randomElement() ?? .pending
            let randomBudget = Double.random(in: 10.0...100.0)
            let randomIsOutdoor = Bool.random()
            let randomDate = Date().addingTimeInterval(Double.random(in: -31536000...31536000)) // Random date within a year
            
            let hangout = Hangout(
                hangoutId: UUID().uuidString,
                date: randomDate,
                duration: randomDuration,
                vibe: randomVibe,
                status: randomStatus,
                participantIds: randomParticipants,
                location: randomLocation,
                title: randomTitle,
                description: randomDescription,
                tags: Array(randomTags),
                budget: randomBudget,
                isOutdoor: randomIsOutdoor)
            
            randomHangouts.append(hangout)
        }
        
        return randomHangouts
    }
    
}

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
