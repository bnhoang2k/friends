//
//  VertexModel.swift
//  friends
//
//  Created by Bryan Hoang on 12/6/24.
//

import Foundation
import FirebaseFirestore
import FirebaseVertexAI
import GooglePlacesSwift

struct Location: Codable, Equatable {
    let name: String
    let description: String?
    
    init(name: String, location: String, description: String? = nil) {
        self.name = name
        self.description = description
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, description
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
        /*
         Temperature: A temperature of 0.7 strikes a balance between creativity and reliability. It introduces enough
         randomness to avoid overly deterministic (predictable) responses while still maintaining coherence. This is
         great for brainstorming hangout ideas, where you want variety but also relevant suggestions.
        
         Top-P: A top-P value of 0.9 allows the model to consider tokens that make up 90% of the total probability mass.
         This ensures it picks from a wide range of plausible options while still filtering out unlikely ones. It
         encourages creative responses by keeping slightly less probable but interesting choices.
        
         Top-K: With top-K set to 40, the model considers up to the top 40 most likely options for each token. This provides
         a good balance of randomness without being too chaotic. It ensures the model has enough variety in token selection
         without becoming incoherent.
        
         Candidate Count: Setting candidateCount to 1 means the model will only return the best result from the sampling process.
         This simplifies the output for the user. Higher Values: Increasing this (e.g., 3) could give you multiple alternative
         responses to pick from, but it adds complexity to the UI since you’ll need to handle multiple candidates.
        
         Max Output Tokens: This sets the maximum length of the response. For hangout ideas or similar tasks, 256 tokens
         are sufficient to generate a few paragraphs or a well-detailed table of suggestions.
        
         Stop Sequences: Not specifying stop sequences means the model will generate text until it reaches the maximum token
         limit or finishes the task naturally. This works well for open-ended generation like hangout ideas.
        
         Response MIME Type:  Leaving this as nil defaults to plain text. For most tasks, this is ideal unless you’re working
         with specific formats like JSON or Markdown.
         */
        let locationSchema = Schema.object(properties: [
            "name" : .string(),
            "description" : .string()
        ],
                                           optionalProperties: [],
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
            parts: "Focus on 1) Vibe, 2) Hangout Duration, and 3) Budget, in that order of importance. If no specific participant information is available, recommend popular, interesting places based on today’s trends in Denver, CO. Avoid repeating ideas from previous suggestions. Do not include any headers, titles, explanations, or commentary."
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
        defer {inProgress = false}

        guard let model else {return}

        do {
            inProgress = true
            errorMessage = nil
            outputText = ""

            let prompt = """
            Provide a list of at least four places that users would enjoy based on the input: \(self.userInput). Try to avoid the previously suggested places: \(previousSuggestions.joined(separator: ", ")).
            The response must strictly be in JSON format as an array of at least four objects.
            Do not include any text or commentary outside the JSON array.
            """

            let outputContentStream = try model.generateContentStream(prompt)

            for try await outputContent in outputContentStream {
                guard let line = outputContent.text else {
                    return
                }
                outputText += line
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

}

extension VertexViewModel {
    func parseStructuredOutput(_ output: String) async -> [Place]? {
        guard let data = output.data(using: .utf8) else {
            print("Failed to convert output to Data")
            return nil
        }
        print(output)
        do {
            // Decode JSON into an array of `Location` objects
            let locations = try JSONDecoder().decode([Location].self, from: data)
            
            var res: [Place] = []
            for location in locations {
                let places = try await PlacesManager.shared.fetchPlaceDetails(name: location.name)
                for place in places {
                    res.append(place)
                }
                previousSuggestions.insert(location.name)
            }
            return res
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Key '\(key)' not found: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Type mismatch for type '\(type)': \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let value, let context) {
            print("Value '\(value)' not found: \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            print("Data corrupted: \(context.debugDescription)")
        } catch {
            print("Unexpected decoding error: \(error)")
        }
        return nil
    }
}
