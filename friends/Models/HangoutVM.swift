//
//  HangoutVM2.swift
//  friends
//
//  Created by Bryan Hoang on 5/9/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class HangoutVM: ObservableObject {
    @Published var references: [HangoutReference] = []
    private var summaryListener: ListenerRegistration?
    
    // MARK: - Public API
    
    /// Start a real‑time listener on `/users/{uid}/hangouts`,
    /// streaming adds/mods/removals into `references`.
    /// Firestore will cache all of these summary docs on disk automatically.
    func startListeningToMySummaries(uid: String) {
        // Only attach once
        guard summaryListener == nil else { return }
        
        let coll = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("hangouts")
            .order(by: "creation_date", descending: true)
        
        // This primes both memory & disk cache for summary docs
        summaryListener = coll.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let docs = snapshot?.documents else {
                print("HangoutVM2 listener error:", error?.localizedDescription ?? "unknown")
                return
            }
            self.references = docs.compactMap { try? $0.data(as: HangoutReference.self) }
        }
    }
    
    /// Stop the real‑time listener and clear out state.
    /// Call on sign‑out or when you no longer need summaries.
    func removeListeners() {
        summaryListener?.remove()
        summaryListener = nil
        references.removeAll()
    }
    
    /// One‑off “cache‑first, then server” load of all summaries.
    /// Useful if we want to pre‑populate `references` before attaching a listener,
    /// or refresh everything on demand.
    func loadMySummariesCacheFirst(uid: String) {
        let coll = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("hangouts")
            .order(by: "creation_date", descending: true)
        
        // 1) Try cache
        coll.getDocuments(source: .cache) { [weak self] snap, error in
            if let docs = snap?.documents, !docs.isEmpty {
                self?.references = docs.compactMap {
                    try? $0.data(as: HangoutReference.self)
                }
            } else {
                // 2) Fallback to server
                coll.getDocuments { snap, error in
                    guard let docs2 = snap?.documents else {
                        print("Error fetching summaries from server:", error?.localizedDescription ?? "unknown")
                        return
                    }
                    self?.references = docs2.compactMap {
                        try? $0.data(as: HangoutReference.self)
                    }
                }
            }
        }
    }
    
    /// Fetch the full `Hangout` document on‑demand.
    /// Firestore will cache it on disk when first read.
    func fetchFullHangout(_ ref: HangoutReference) async throws -> Hangout {
        guard let hangoutId = ref.id else {
            throw NSError(domain: "HangoutVM2", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Missing hangoutId"])
        }
        let docRef = Firestore.firestore()
            .collection("hangouts")
            .document(hangoutId)
        return try await docRef.getDocument(as: Hangout.self)
    }
}

extension HangoutVM {
    func filterHangoutByFriend(_ friendId: String) -> [HangoutReference] {
        return references
            .filter { $0.participantIds.contains(friendId) }
            .sorted {$0.creationDate > $1.creationDate}
    }
}

extension HangoutVM {
    func createHangout(uid: String, hangout: Hangout) async throws {
        try await HangoutManager.shared.createHangout(uid: uid, hangout: hangout)
    }
}
