//
//  HangoutManager.swift
//  friends
//
//  Created by Bryan Hoang on 12/10/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

final class HangoutManager {
    static let shared = HangoutManager()
    private init() {}
    
    // High-level hangout collection
    private let hangoutCollection = Firestore.firestore().collection("hangouts")
    
    // Low-level hangout collection holding hangout reference files.
    func userHangoutCollection(uid: String) -> CollectionReference {
        return UserManager.shared.userDocument(uid: uid).collection("hangouts")
    }
    
    func hangoutDocument(hangoutId: String) -> DocumentReference {
        return hangoutCollection.document(hangoutId)
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        //        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        //        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

extension HangoutManager {
    func createHangout(uid: String, hangout: Hangout) async throws {
        
        // When hangouts are created; our idea is as follows:
        // 1. Create a document holding all of the information in a huge
        // database for all hangouts. This is the master file that'll hold
        // all of the hangout's information.
        // 2. Create a "low-level" meta-document within the user's
        // subcollection. It only holds sparse information and will
        // point to the high-level document containg all of the information.
        
        let functions = Functions.functions()
        
        // Prepare data for the Cloud Function call
        // Note: We don't use hangout_id because we're using a placeholder
        // UUID value for it due to defaultHangout(). Therefore, we want to
        // generate it from the firebase function.
        let requestData: [String : Any] = [
//            "hangout_id": hangout.hangoutId,
            "creation_date": hangout.creationDate.timeIntervalSince1970 * 1000, // Unix timestamp in ms
            "duration": hangout.duration.rawValue,
            "vibe": hangout.vibe.rawValue,
//            "status", hangout.status.rawValue,
            "participant_ids": hangout.participantIds,
            "location": hangout.location ?? "",
            "title": hangout.title ?? "",
            "description": hangout.description ?? "",
            "tags": hangout.tags ?? [],
            "budget": hangout.budget,
            "is_outdoor": hangout.isOutdoor,
            "uid" : uid,
        ]
        
        do {
            let result = try await functions.httpsCallable("createHangout").call(requestData)
            
            // The Cloud Function should return something like { "hangout_id": "..." }
            guard let hangoutReference = result.data as? [String: Any],
                  let hangoutId = hangoutReference["hangout_id"] as? String else {
                print("Error: Invalid data received from Cloud Function.")
                return
            }
            
            print("Successfully created hangout with ID: \(hangoutId)")
        } catch {
            // Handle errors from the function call
            print("Error calling createHangout function: \(error)")
            throw error
        }
    }
}
