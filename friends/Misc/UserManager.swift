//
//  UserManager.swift
//  friends
//
//  Created by Bryan Hoang on 8/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser {
    let uid: String?
    let email: String?
    let dateCreated: Date?
}

final class UserManager {
    
    static let shared = UserManager()
    private init() {}
    
    func createNewUser(adr: AuthDataResultModel) async throws {
        let userData: [String: Any] = [
            "uid" : adr.uid,
            "date_created" : Timestamp(),
            "email" : adr.email ?? ""
        ]
        try await Firestore.firestore().collection("users").document(adr.uid).setData(userData, merge: false)
    }
    
    func getUser(uid: String) async throws -> DBUser {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        
        guard let data = snapshot.data(),
              let uid = data["user_id"] as? String else {
            // TODO: Create actual error.
            throw URLError(.badServerResponse)
        }
        
        let email = data["email"] as? String
        let dateCreated = data["data_created"] as? Date
        
        return DBUser(uid: uid, email: email, dateCreated: dateCreated)
    }
}
