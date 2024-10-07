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
    private init() {}
}

// Google Cloud
extension TypesenseManager {
    func fetchAPIKey() async throws -> String? {
        do {
            let result = try await functions.httpsCallable("getTypesenseAPIKey").call(["test": "data"])
            if let data = result.data as? [String: Any],
               let apiKey = data["apiKey"] as? String {
                return apiKey
            } else {
                throw NSError(domain: "TypesenseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        } catch {
            print("Failed to fetch API key: \(error.localizedDescription)")
            throw error // Re-throw the error to propagate it
        }
    }
}
