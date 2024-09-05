
//  UserManager.swift
//  friends
//
//  Created by Bryan Hoang on 8/12/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

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
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case dateCreated = "date_created"
        case username = "username"
        case email = "email"
        case photoURL = "photo_url"
        case fullName = "full_name"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated)
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.uid, forKey: .uid)
        try container.encodeIfPresent(self.dateCreated, forKey: .dateCreated)
        try container.encodeIfPresent(self.username, forKey: .username)
        try container.encodeIfPresent(self.email, forKey: .email)
        try container.encodeIfPresent(self.photoURL, forKey: .photoURL)
        try container.encodeIfPresent(self.fullName, forKey: .fullName)
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
        //        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        //        decoder.keyDecodingStrategy = .convertFromSnakeCase
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
    
    func updateUser(_ originalUser: DBUser, with modifiedUser: DBUser) async throws {
        var data: [String: Any] = [:]

        if originalUser.username != modifiedUser.username {
            data["username"] = modifiedUser.username
        }

        if originalUser.fullName != modifiedUser.fullName {
            data["full_name"] = modifiedUser.fullName
        }

        if originalUser.email != modifiedUser.email {
            data["email"] = modifiedUser.email
        }

        if originalUser.photoURL != modifiedUser.photoURL {
            data["photo_url"] = modifiedUser.photoURL
        }

        // If there are changes, update the Firestore document
        if !data.isEmpty {
            try await userDocument(uid: modifiedUser.uid).updateData(data)
        }
    }
    
    func uploadProfileImage(uid: String, imageData: Data) async throws -> String {
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("users/\(uid)/profile_picture.jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the image data
        let _ = try await profileImageRef.putDataAsync(imageData, metadata: metadata)
        
        // Retrieve the download URL
        let downloadURL = try await profileImageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func updateUserProfileImageURL(uid: String, downloadURL: String) async throws {
        let data: [String: Any] = ["photo_url": downloadURL]
        try await userCollection.document(uid).updateData(data)
    }
}
