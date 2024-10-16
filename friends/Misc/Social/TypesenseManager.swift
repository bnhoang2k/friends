//
//  TypesenseManager.swift
//  friends
//
//  Created by Bryan Hoang on 9/19/24.
//

// TypesenseManager.swift
import Foundation
import Typesense
import FirebaseFunctions

@MainActor
final class TypesenseManager {
    static let shared = TypesenseManager()
    let functions = Functions.functions(region: "us-central1")
    
    private var apiKey: String? = nil
    private var apiKeyTask: Task<String, Error>? = nil
    
    private init() {}
}

// Google Cloud
extension TypesenseManager {
    func fetchAPIKey() async throws -> String {
        // If the key is already available, return it
        if let existingKey = apiKey {
            return existingKey
        }
        
        // If a fetch task is already running, await its result
        if let existingTask = apiKeyTask {
            return try await existingTask.value
        }
        
        // Start a new fetch task
        let newTask = Task {
            let result = try await functions.httpsCallable("getTypesenseAPIKey").call(["test": "data"])
            guard let data = result.data as? [String: Any], let fetchedKey = data["apiKey"] as? String else {
                throw NSError(domain: "TypesenseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
            self.apiKey = fetchedKey // Cache the key
            return fetchedKey
        }
        
        // Assign the ongoing task to `apiKeyTask` so subsequent calls can await its result
        self.apiKeyTask = newTask
        
        do {
            let fetchedKey = try await newTask.value
            self.apiKeyTask = nil // Clear the task after successful completion
            return fetchedKey
        } catch {
            self.apiKeyTask = nil // Clear the task in case of failure
            throw error
        }
    }
}
