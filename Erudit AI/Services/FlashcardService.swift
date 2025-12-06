//
//  FlashcardService.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

/// Service for managing flashcards in Firestore
class FlashcardService: ObservableObject {
    static let shared = FlashcardService()
    
    private let firestore = Firestore.firestore()
    private let auth = Auth.auth()
    
    // Published properties for real-time updates
    @Published var flashcards: [Flashcard] = []
    @Published var dueFlashcards: [Flashcard] = []
    @Published var statistics: FlashcardStatistics = FlashcardStatistics(total: 0, due: 0, new: 0)
    
    private var flashcardsListener: ListenerRegistration?
    private var dueFlashcardsListener: ListenerRegistration?
    
    private init() {}
    
    /// Get current user ID
    private var currentUserId: String? {
        return auth.currentUser?.uid
    }
    
    /// Get flashcards collection reference
    private var flashcardsCollection: CollectionReference {
        guard let userId = currentUserId else {
            fatalError("User not authenticated")
        }
        return firestore.collection("flashcards")
    }
    
    // MARK: - Basic CRUD Operations
    
    /// Get all flashcards for current user
    func getFlashcards() async throws -> [Flashcard] {
        guard currentUserId != nil else {
            throw FlashcardError.userNotAuthenticated
        }
        
        let snapshot = try await flashcardsCollection
            .whereField("userId", isEqualTo: currentUserId!)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Flashcard.fromFirestore(id: document.documentID, data: document.data())
        }
    }
    
    /// Get flashcards due for review
    func getDueFlashcards() async throws -> [Flashcard] {
        guard let userId = currentUserId else {
            throw FlashcardError.userNotAuthenticated
        }
        
        // Get all flashcards for user and filter locally
        let snapshot = try await flashcardsCollection
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let allFlashcards = snapshot.documents.compactMap { document in
            Flashcard.fromFirestore(id: document.documentID, data: document.data())
        }
        
        let now = Date()
        
        // Filter cards that are due (nextReview is null or <= now)
        let dueCards = allFlashcards.filter { flashcard in
            guard let nextReview = flashcard.nextReview else { return true } // null = due
            return nextReview <= now
        }
        
        // Sort with null nextReview first, then by nextReview time
        return dueCards.sorted { card1, card2 in
            let time1 = card1.nextReview?.timeIntervalSince1970 ?? 0
            let time2 = card2.nextReview?.timeIntervalSince1970 ?? 0
            return time1 < time2
        }
    }
    
    /// Get flashcards by book ID
    func getFlashcardsByBook(_ bookId: String) async throws -> [Flashcard] {
        guard currentUserId != nil else {
            throw FlashcardError.userNotAuthenticated
        }
        
        let snapshot = try await flashcardsCollection
            .whereField("userId", isEqualTo: currentUserId!)
            .whereField("bookId", isEqualTo: bookId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Flashcard.fromFirestore(id: document.documentID, data: document.data())
        }
    }
    
    /// Add a new flashcard
    func addFlashcard(_ flashcard: Flashcard) async throws -> String {
        let docRef = try await flashcardsCollection.addDocument(data: flashcard.toFirestore())
        return docRef.documentID
    }
    
    /// Update an existing flashcard
    func updateFlashcard(_ flashcard: Flashcard) async throws {
        try await flashcardsCollection.document(flashcard.id).updateData(flashcard.toFirestore())
    }
    
    /// Delete a flashcard
    func deleteFlashcard(_ flashcardId: String) async throws {
        try await flashcardsCollection.document(flashcardId).delete()
    }
    
    // MARK: - Spaced Repetition Algorithm
    
    /// Update flashcard after review (Spaced Repetition Algorithm)
    func updateAfterReview(_ flashcardId: String, quality: Int) async throws {
        let document = try await flashcardsCollection.document(flashcardId).getDocument()
        
        guard document.exists, let data = document.data() else {
            throw FlashcardError.flashcardNotFound
        }
        
        guard let flashcard = Flashcard.fromFirestore(id: flashcardId, data: data) else {
            throw FlashcardError.flashcardNotFound
        }
        
        let updatedFlashcard = Flashcard.calculateNextReview(flashcard, quality: quality)
        try await updateFlashcard(updatedFlashcard)
    }
    
    // MARK: - Statistics
    
    /// Get statistics for current user
    func getStatistics() async throws -> FlashcardStatistics {
        guard currentUserId != nil else {
            throw FlashcardError.userNotAuthenticated
        }
        
        let snapshot = try await flashcardsCollection
            .whereField("userId", isEqualTo: currentUserId!)
            .getDocuments()
        
        let flashcards = snapshot.documents.compactMap { document in
            Flashcard.fromFirestore(id: document.documentID, data: document.data())
        }
        
        let now = Date()
        let dueCount = flashcards.filter { $0.isDue }.count
        let totalCount = flashcards.count
        let newCount = flashcards.filter { $0.repetitions == 0 }.count
        
        return FlashcardStatistics(
            total: totalCount,
            due: dueCount,
            new: newCount
        )
    }
    
    // MARK: - Real-time Updates
    
    /// Start listening to flashcards changes
    func startListeningToFlashcards() {
        guard let userId = currentUserId else { 
            print("⚠️ No user ID available for listening to flashcards")
            return 
        }
        
        print("🎧 Starting to listen to flashcards for user: \(userId)")
        
        flashcardsListener = flashcardsCollection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to flashcards: \(error)")
                    return
                }
                
                guard let snapshot = snapshot else { 
                    print("⚠️ No snapshot received")
                    return 
                }
                
                print("📦 Received snapshot with \(snapshot.documents.count) documents")
                
                DispatchQueue.main.async {
                    self.flashcards = snapshot.documents.compactMap { document in
                        let flashcard = Flashcard.fromFirestore(id: document.documentID, data: document.data())
                        if flashcard == nil {
                            print("⚠️ Failed to parse flashcard document: \(document.documentID)")
                            print("Document data: \(document.data())")
                        }
                        return flashcard
                    }
                    print("✅ Loaded \(self.flashcards.count) flashcards successfully")
                    self.updateStatistics()
                }
            }
    }
    
    /// Start listening to due flashcards changes
    func startListeningToDueFlashcards() {
        guard let userId = currentUserId else { return }
        
        let now = Date()
        let nowTimestamp = Timestamp(date: now)
        
        dueFlashcardsListener = flashcardsCollection
            .whereField("userId", isEqualTo: userId)
            .whereField("nextReview", isLessThanOrEqualTo: nowTimestamp)
            .order(by: "nextReview")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to due flashcards: \(error)")
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                DispatchQueue.main.async {
                    self.dueFlashcards = snapshot.documents.compactMap { document in
                        Flashcard.fromFirestore(id: document.documentID, data: document.data())
                    }
                }
            }
    }
    
    /// Stop all listeners
    func stopListening() {
        flashcardsListener?.remove()
        dueFlashcardsListener?.remove()
        flashcardsListener = nil
        dueFlashcardsListener = nil
    }
    
    /// Update statistics based on current flashcards
    private func updateStatistics() {
        let now = Date()
        let dueCount = flashcards.filter { $0.isDue }.count
        let totalCount = flashcards.count
        let newCount = flashcards.filter { $0.repetitions == 0 }.count
        
        statistics = FlashcardStatistics(
            total: totalCount,
            due: dueCount,
            new: newCount
        )
    }
}

// MARK: - Statistics Model
struct FlashcardStatistics {
    let total: Int
    let due: Int
    let new: Int
}

// MARK: - Error Handling
enum FlashcardError: LocalizedError {
    case userNotAuthenticated
    case flashcardNotFound
    case firestoreError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .flashcardNotFound:
            return "Flashcard not found"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
}
