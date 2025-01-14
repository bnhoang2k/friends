//
//  HangoutVM.swift
//  friends
//
//  Created by Bryan Hoang on 1/14/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class HangoutVM: ObservableObject {
    @Published var cachedHangoutsList: [HangoutReference: Hangout] = [:]
    private var listeners: [ListenerRegistration] = []
    private var currentHangoutListener: ListenerRegistration?
    @Published var selectedFriendId: String?
    
    private var lastDocument: DocumentSnapshot? = nil
}

/// Initial Fetch Functions
extension HangoutVM {
    func fetchHangouts(uid: String, friendId: String) async throws {
        let hangoutList = HangoutManager.shared.userHangoutCollection(uid: uid)
        
        let query = hangoutList
            .whereField(HangoutReference.CodingKeys.participantIds.rawValue, arrayContains: friendId)
            .order(by: "creation_date", descending: true)
            .limit(to: 10)
            .start(afterDocument: lastDocument)
        
        let snapshot = try await query.getDocuments()
        for doc in snapshot.documents {
            guard let request = try? doc.data(as: HangoutReference.self) else { continue }
            await fetchHangoutDetails(hangoutReference: request)
        }
        lastDocument = snapshot.documents.last
    }
    func fetchHangoutDetails(hangoutReference: HangoutReference, forceUpdate: Bool = false) async {
        // Check if hangout details are already cached
        if let _ = cachedHangoutsList[hangoutReference], !forceUpdate {
            return
        }
        let hangoutRef = HangoutManager.shared.hangoutDocument(hangoutId: hangoutReference.hangoutId)
        do {
            let document = try await hangoutRef.getDocument()
            if let hangout = try? document.data(as: Hangout.self) {
                self.cachedHangoutsList[hangoutReference] = hangout
            }
        } catch {
            print("Error fetching hangout details: \(error.localizedDescription)")
        }
    }
}

/// Hangout - Related Functions
extension HangoutVM {
    func createHangout(uid: String, hangout: Hangout) async throws {
        try await HangoutManager.shared.createHangout(uid: uid, hangout: hangout)
    }
    func getFilteredHangoutsByFriend(friendId: String) -> [Hangout] {
        // Extract hangouts from the cachedHangoutsList dictionary
        var filteredHangouts = Array(cachedHangoutsList.values)
        
        // Sort the hangouts by creation date, with a tiebreaker using hangout ID
        filteredHangouts.sort { (hangout1, hangout2) in
            if hangout1.creationDate != hangout2.creationDate {
                return hangout1.creationDate > hangout2.creationDate // Sort by most recent date
            } else {
                return hangout1.hangoutId < hangout2.hangoutId // Use hangout ID as tiebreaker
            }
        }
        
        // Return the sorted list
        return filteredHangouts
    }
}

/// Listeners
extension HangoutVM {
    func listenForHangouts(for friendId: String, uid: String) {
        // Stop the current listener if it's already active
        if currentHangoutListener != nil {
            stopCurrentHangoutListener()
        }
        
        // Update the selected friend ID
        self.selectedFriendId = friendId
        
        // Start a new listener for the selected friend
        let hangoutsCollection = HangoutManager.shared.userHangoutCollection(uid: uid)
            .whereField(HangoutReference.CodingKeys.participantIds.rawValue, arrayContains: friendId)
            .order(by: "creation_date", descending: true)
            .limit(to: 10)
        
        currentHangoutListener = hangoutsCollection.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let snapshot = snapshot else {
                print("Error fetching hangouts for \(friendId): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            snapshot.documentChanges.forEach { diff in
                switch diff.type {
                case .added:
                    if let hangoutRef = try? diff.document.data(as: HangoutReference.self) {
                        Task { await self.fetchHangoutDetails(hangoutReference: hangoutRef) }
                    }
                case .modified:
                    if let hangoutRef = try? diff.document.data(as: HangoutReference.self) {
                        Task { await self.fetchHangoutDetails(hangoutReference: hangoutRef, forceUpdate: true) }
                    }
                case .removed:
                    if let hangoutRef = try? diff.document.data(as: HangoutReference.self) {
                        self.cachedHangoutsList.removeValue(forKey: hangoutRef)
                    }
                }
            }
        }
    }
    func stopCurrentHangoutListener() {
        // Stop the currently active listener if it exists
        currentHangoutListener?.remove()
        currentHangoutListener = nil
//        self.selectedFriendId = nil
        print("Current hangout listener stopped.")
    }
    
    func removeListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        currentHangoutListener?.remove()
    }
}

extension Query {
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T: Decodable {
        return try await getDocumentsWithSnapshot(as: type).result
    }
    func getDocumentsWithSnapshot<T>(as type: T.Type) async throws -> (result: [T], lastDocument: DocumentSnapshot?) where T: Decodable {
        let snapshot = try await self.getDocuments()
        let result = try snapshot.documents.map { document in
            try document.data(as: T.self)
        }
        return (result, snapshot.documents.last)
    }
    func start(afterDocument lastDocument: DocumentSnapshot?) -> Query {
        guard let lastDocument else { return self }
        return self.start(afterDocument: lastDocument)
    }
}
