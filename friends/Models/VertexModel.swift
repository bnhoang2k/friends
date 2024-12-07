//
//  VertexModel.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseVertexAI

struct Location: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let location: String
    let description: String
    var imageURL: String? = nil
}

@MainActor
class VertexViewModel: ObservableObject {
    
    @Published var userInput: String = ""
    @Published var outputText: String = ""
    @Published var errorMessage: String? = nil
    @Published var inProgress: Bool = false
    
    private var model: GenerativeModel?
    
    init() {
        // Can change models here https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models
        model = VertexAI.vertexAI().generativeModel(modelName: "gemini-1.5-flash")
    }
    
    // Main function to perform reasoning based on user input and selected images.
    func reason() async {
        // The defer statement schedules code to run after the function finishes (either normally or with an error).
        // In this case, it ensures `inProgress` is set to false, no matter what happens (even in case of an error).
        defer {
            inProgress = false
        }
        
        // Check if the model is available.
        guard let model else {
            return
        }
        
        do {
            // Set state to indicate processing is in progress.
            inProgress = true
            errorMessage = nil
            outputText = ""
            
            // Prepare the prompt for the AI model.
            let prompt = "Provide a list of at least four places that users would enjoy based on the input: \(self.userInput). Focus on 1) Vibe, 2) Hangout Duration, and 3) Budget, in that order of importance. If no specific participant information is available, recommend popular, interesting places based on today’s trends and location. The response **must only** include a markdown table with exactly two columns: Place Name and Why It's Good. Do not include any headers, titles, explanations, or commentary before or after the table."
            
            // Use the model to generate a response based on the prompt and images.
            let outputContentStream = model.generateContentStream(prompt)
            
            // Stream the response from the model.
            for try await outputContent in outputContentStream {
                // Get each line of text from the response.
                guard let line = outputContent.text else {
                    return
                }
                
                // Append each line to the outputText.
                outputText = (outputText) + line
            }
        } catch {
            // If an error occurs, log the error and set the error message for the UI.
            errorMessage = error.localizedDescription
        }
    }
}
