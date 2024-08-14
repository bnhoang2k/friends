
//  UserManager.swift
//  friends
//
//  Created by Bryan Hoang on 8/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser: Codable {
    // Some field information is acquired differently based on sign-in method.
    // We'll separate the fields out based on that fact.
    
    // Norm.
    var uid: String
    var dateCreated: Date?
    var username: String?
    
    // Dependent
    var email: String?
    var photoURL: String?
    var fullName: String?
    
    init(uid: String,
         dateCreated: Date? = nil,
         username: String? = nil,
         email: String? = nil,
         photoURL: String? = nil,
         fullName: String? = nil) {
        self.uid = uid
        self.dateCreated = dateCreated
        self.username = username
        self.email = email
        self.photoURL = photoURL
        self.fullName = fullName
    }
    
    init(auth: AuthDataResultModel) {
        self.uid = auth.uid
        self.dateCreated = Date()
        self.username = auth.username
        
        self.email = auth.email
        self.photoURL = auth.photo_url
        self.fullName = auth.fullName
    }
    
    func updateUsername(newUsername: String) -> DBUser {
        return DBUser(uid: uid,
                      dateCreated: dateCreated,
                      username: newUsername,
                      email: email,
                      photoURL: photoURL,
                      fullName: fullName)
    }
    
    func updateFN(newFN: String) -> DBUser {
        return DBUser(uid: uid,
                      dateCreated: dateCreated,
                      username: username,
                      email: email,
                      photoURL: photoURL,
                      fullName: newFN)
    }
    
    func updateEmail(newEmail: String) -> DBUser {
        return DBUser(uid: uid,
                      dateCreated: dateCreated,
                      username: username,
                      email: newEmail,
                      photoURL: photoURL,
                      fullName: fullName)
    }
}

final class UserManager {
    static let shared = UserManager()
    private init() {}
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(uid: String) -> DocumentReference {
        return userCollection.document(uid)
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

// MARK: User Functions
extension UserManager {
    func createNewUser(user: DBUser) async throws {
        // TODO: Convert to update data instead. 34:03 #10
        try userDocument(uid: user.uid).setData(from: user,
                                                merge: false,
                                                encoder: encoder)
    }
    
    func getUser(uid: String) async throws -> DBUser {
        try await userDocument(uid: uid).getDocument(as: DBUser.self,
                                                     decoder: decoder)
    }
    
    func doesUserExist(uid: String) async throws -> Bool {
        let document = try await userDocument(uid: uid).getDocument()
        return document.exists
    }
    
    func updateUsername(user: DBUser) async throws {
        let data: [String:Any] = [
            "username" : user.username ?? "USERNAME ERROR"
        ]
        try await userDocument(uid: user.uid).updateData(data)
    }
    
    func updateFN(user: DBUser) async throws {
        let data: [String:Any] = [
            "full_name" : user.fullName ?? "FULLNAME ERROR"
        ]
        try await userDocument(uid: user.uid).updateData(data)
    }
    
    func updateEmail(user: DBUser) async throws {
        let data: [String:Any] = [
            "email" : user.email ?? "EMAIL ERROR"
        ]
        try await userDocument(uid: user.uid).updateData(data)
    }
}
