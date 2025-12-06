//
//  SimpleFlashcardService.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import Foundation
import Combine
import FirebaseAuth

/// Simple service for flashcard generation using Railway API only
class SimpleFlashcardService: ObservableObject {
    static let shared = SimpleFlashcardService()
    
    private let aiService = AIService.shared
    private let flashcardService = FlashcardService.shared
    
    // Published properties for UI updates
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generate and save flashcards from highlighted text
    func generateAndSaveFlashcards(
        highlightedText: String,
        bookTitle: String,
        bookId: String,
        count: Int = 3
    ) async throws -> [Flashcard] {
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            // Generate flashcards using Railway API
            let generatedFlashcards = try await aiService.generateFlashcards(
                highlightedText: highlightedText,
                bookTitle: bookTitle,
                count: count
            )
            
            // Update flashcards with book ID and user ID
            let userId = Auth.auth().currentUser?.uid ?? ""
            let updatedFlashcards = generatedFlashcards.map { flashcard in
                flashcard.copyWith(
                    bookId: bookId,
                    userId: userId
                )
            }
            
            // Save to Firebase
            for flashcard in updatedFlashcards {
                _ = try await flashcardService.addFlashcard(flashcard)
            }
            
            return updatedFlashcards
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Test connection to Railway API
    func testConnection() async -> Bool {
        return await aiService.testConnection()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Get current user ID
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
}

