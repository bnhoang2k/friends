//
//  VertexModel.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import Foundation
import FirebaseFirestore
import FirebaseVertexAI

struct Location: Codable, Equatable {
    let name: String
    let location: String
    let description: String
    var imageURL: String? = nil
    
    init(name: String, location: String, description: String, imageURL: String? = nil) {
        self.name = name
        self.location = location
        self.description = description
        self.imageURL = imageURL
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, location, description, imageURL
    }
}

@MainActor
class VertexViewModel: ObservableObject {
    
    @Published var userInput: String = ""
    @Published var outputText: String = ""
    @Published var errorMessage: String? = nil
    @Published var inProgress: Bool = false
    
    @Published var previousSuggestions: Set<String> = []
    
    private var model: GenerativeModel?
    var config : GenerationConfig?
    var systemInstruction: ModelContent?
    
    init() {
        // Temperature: A temperature of 0.7 strikes a balance between creativity and reliability. It introduces enough
        // randomness to avoid overly deterministic (predictable) responses while still maintaining coherence. This is
        // great for brainstorming hangout ideas, where you want variety but also relevant suggestions.
        
        // Top-P: A top-P value of 0.9 allows the model to consider tokens that make up 90% of the total probability mass.
        // This ensures it picks from a wide range of plausible options while still filtering out unlikely ones. It
        // encourages creative responses by keeping slightly less probable but interesting choices.
        
        // Top-K: With top-K set to 40, the model considers up to the top 40 most likely options for each token. This provides
        // a good balance of randomness without being too chaotic. It ensures the model has enough variety in token selection
        // without becoming incoherent.
        
        // Candidate Count: Setting candidateCount to 1 means the model will only return the best result from the sampling process.
        // This simplifies the output for the user. Higher Values: Increasing this (e.g., 3) could give you multiple alternative
        // responses to pick from, but it adds complexity to the UI since you’ll need to handle multiple candidates.
        
        // Max Output Tokens: This sets the maximum length of the response. For hangout ideas or similar tasks, 256 tokens
        // are sufficient to generate a few paragraphs or a well-detailed table of suggestions.
        
        // Stop Sequences: Not specifying stop sequences means the model will generate text until it reaches the maximum token
        // limit or finishes the task naturally. This works well for open-ended generation like hangout ideas.
        
        // Response MIME Type:  Leaving this as nil defaults to plain text. For most tasks, this is ideal unless you’re working
        // with specific formats like JSON or Markdown.
        let locationSchema = Schema.object(properties: [
            "name" : .string(),
            "location" : .string(),
            "description" : .string(),
            "imageURL" : .string(nullable: true)
        ],
                                           optionalProperties: ["imageURL"],
                                           description: nil,
                                           nullable: false)
        
        let locationArraySchema = Schema.array(items: locationSchema, description: nil, nullable: false)
        
        config = GenerationConfig(temperature: 0.9,
                                  topP: 0.95,
                                  topK: 40,
                                  candidateCount: 1,
                                  maxOutputTokens: 1024,
                                  stopSequences: nil,
                                  responseMIMEType: "application/json",
                                  responseSchema: locationArraySchema)
        systemInstruction = ModelContent(
            role: "You are a friendly and knowledgeable hangout planner.",
            parts: "Focus on 1) Vibe, 2) Hangout Duration, and 3) Budget, in that order of importance. If no specific participant information is available, recommend popular, interesting places based on today’s trends and location. Avoid repeating ideas from previous suggestions. Do not include any headers, titles, explanations, or commentary."
        )
        // Can change models here https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models
        // Look into tools and toolsConfig
        model = VertexAI.vertexAI().generativeModel(modelName: "gemini-1.5-flash",
                                                    generationConfig: config,
                                                    safetySettings: [
                                                        .init(harmCategory: .dangerousContent,
                                                              threshold: .blockNone),
                                                        .init(harmCategory: .harassment,
                                                              threshold: .blockNone),
                                                        .init(harmCategory: .hateSpeech,
                                                              threshold: .blockNone),
                                                        .init(harmCategory: .sexuallyExplicit,
                                                              threshold: .blockNone),
                                                    ],
                                                    tools: nil,
                                                    toolConfig: nil,
                                                    systemInstruction: systemInstruction,
                                                    requestOptions: RequestOptions(timeout: 0))
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
            let prompt = """
            Provide a list of at least four places that users would enjoy based on the input: \(self.userInput). Try to avoid the previously suggested places: \(previousSuggestions.joined(separator: ", ")).
            The response must strictly be in JSON format as an array of at least four objects. 
            Each object must follow this structure:
            [
                {
                    "name": "string", 
                    "location": "string", 
                    "description": "string", 
                    "imageURL": "string or null"
                }
            ]
            Ensure the array contains at least four items. Do not include any text or commentary outside the JSON array.
            """
            
            // Use the model to generate a response based on the prompt and images.
            let outputContentStream = try model.generateContentStream(prompt)
            
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
