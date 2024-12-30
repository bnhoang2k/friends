//
//  Utilities.swift
//  friends
//
//  Created by Bryan Hoang on 6/7/24.
//

import Foundation
import MapKit
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
                location: Location(name: randomLocation ?? "XD",
                                   coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
                title: randomTitle,
                description: randomDescription,
                tags: Array(randomTags),
                budget: randomBudget,
                isOutdoor: randomIsOutdoor)
            
            randomHangouts.append(hangout)
        }
        
        return randomHangouts
    }
    
    func createRandomHangout(uid: String, friendId: String) async throws -> Hangout {
        let sampleTitles = [
            "Beach Bonanza", "Movie Marathon", "Game Night", "Mountain Hiking", "Kayaking Adventure",
            "Board Game Bash", "Cooking Class", "Art Workshop", "Music Jam Session", "Theater Play",
            "Bowling Night", "Amusement Park", "Zoo Trip", "Science Museum", "History Walk",
            "Wine Tasting", "Brewery Tour", "Gardening Workshop", "DIY Crafting", "Coding Hackathon",
            "Photography Walk", "Fishing Expedition", "Yoga Retreat", "Book Club Discussion", "Comedy Show"
        ]

        let sampleDescriptions = [
            "Enjoy a sunny day at the beach with games and snacks.",
            "Watch back-to-back blockbuster movies with friends.",
            "Play a variety of board games and card games.",
            "Explore scenic mountain trails and enjoy the view.",
            "Paddle through calm waters in a kayak adventure.",
            "Compete in classic board games for bragging rights.",
            "Learn to cook delicious meals in a group class.",
            "Unleash your creativity at an art workshop.",
            "Jam together with musical instruments and songs.",
            "Attend a theater play and experience live acting.",
            "Knock down pins at the local bowling alley.",
            "Enjoy thrilling rides at the amusement park.",
            "Meet exotic animals at the city zoo.",
            "Learn about science at an interactive museum.",
            "Walk through historic landmarks and hear their stories.",
            "Sample a variety of wines at a local vineyard.",
            "Tour a brewery and learn how craft beer is made.",
            "Get your hands dirty with a gardening workshop.",
            "Create DIY crafts and take home your creations.",
            "Collaborate on coding projects in a hackathon.",
            "Take stunning photos on a guided photography walk.",
            "Cast a line and relax on a fishing trip.",
            "Find inner peace at a weekend yoga retreat.",
            "Discuss your favorite books with fellow readers.",
            "Laugh out loud at a live comedy performance."
        ]

        let sampleTags = [
            "fun", "outdoor", "group", "adventurous", "relaxing",
            "educational", "creative", "musical", "competitive", "artistic",
            "social", "casual", "nature", "sports", "food",
            "travel", "history", "science", "technology", "fitness",
            "photography", "writing", "crafts", "family", "budget-friendly"
        ]

        let sampleLocations = [
            "Sunny Beach", "Local Cinema", "Friend's House", "Hiking Trail", "Riverbank",
            "Bowling Alley", "Amusement Park", "City Zoo", "Science Museum", "Historic District",
            "Winery", "Craft Brewery", "Community Garden", "Art Studio", "Tech Hub",
            "Concert Hall", "Comedy Club", "Library", "Fishing Dock", "Yoga Studio",
            "Park Pavilion", "Cafe Downtown", "Mountain Cabin", "Bookstore", "Lakeside Campground"
        ]

        let sampleDurations: [HangoutDuration] = [
            .quick, .halfDay, .fullDay, .overnight
        ]

        let sampleVibes: [HangoutVibe] = [
            .adventurous, .calm, .chill, .energetic, .exciting, .relaxing, .social, .wild
        ]

        let sampleStatuses: [HangoutStatus] = [
            .pending, .confirmed, .cancelled, .completed
        ]

        let randomTitle = sampleTitles.randomElement()
        let randomDescription = sampleDescriptions.randomElement()
        let randomTags = sampleTags.shuffled().prefix(Int.random(in: 1...5))
        let randomLocation = sampleLocations.randomElement()
        let randomDuration = sampleDurations.randomElement() ?? .quick
        let randomVibe = sampleVibes.randomElement() ?? .chill
        let randomStatus = sampleStatuses.randomElement() ?? .pending
        let randomBudget = Double.random(in: 10.0...1000.0)
        let randomIsOutdoor = Bool.random()
        let randomDate = Date().addingTimeInterval(Double.random(in: -31536000...31536000))

        // Randomizing coordinates: Latitude (-90 to 90), Longitude (-180 to 180)
        let randomLatitude = Double.random(in: -90.0...90.0)
        let randomLongitude = Double.random(in: -180.0...180.0)

        let hangout = Hangout(
            hangoutId: UUID().uuidString,
            date: randomDate,
            duration: randomDuration,
            vibe: randomVibe,
            status: randomStatus,
            participantIds: [uid, friendId],
            location: Location(
                name: randomLocation ?? "Unknown Location",
                coordinate: CLLocationCoordinate2D(latitude: randomLatitude, longitude: randomLongitude)
            ),
            title: randomTitle,
            description: randomDescription,
            tags: Array(randomTags),
            budget: randomBudget,
            isOutdoor: randomIsOutdoor
        )

        return hangout
    }
    
    func openBusinessInAppleMaps(
        name: String, near coordinate: CLLocationCoordinate2D
    ) {
        // 1. Create an MKLocalSearch request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = name  // e.g., "Joe's Coffee"
        
        // 2. Define a region around the coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        request.region = MKCoordinateRegion(center: coordinate, span: span)
        
        // 3. Start the local search
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, !response.mapItems.isEmpty else {
                print(
                    "No map items found or error: \(error?.localizedDescription ?? "none")"
                )
                return
            }
            
            // 4. Pick the first (or best) match
            let mapItem = response.mapItems[0]
            
            // 5. Open it in Apple Maps
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }
    
}

extension View {
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
