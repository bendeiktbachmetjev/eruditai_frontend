//
//  AIService.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import Combine

/// Service for AI-powered flashcard generation using Railway API
class AIService: ObservableObject {
    static let shared = AIService()
    
    // Railway API endpoint
    private let baseURL = "https://eruditai-production.up.railway.app/api/generate-flashcards"
    
    // Published properties for UI updates
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generate flashcards from highlighted text
    func generateFlashcards(
        highlightedText: String,
        bookTitle: String,
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
            let flashcards = try await performGeneration(
                highlightedText: highlightedText,
                bookTitle: bookTitle,
                count: count
            )
            
            return flashcards
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Test API connection
    func testConnection() async -> Bool {
        do {
            let _ = try await performGeneration(
                highlightedText: "test",
                bookTitle: "test",
                count: 1
            )
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Perform the actual API call to Railway
    private func performGeneration(
        highlightedText: String,
        bookTitle: String,
        count: Int
    ) async throws -> [Flashcard] {
        
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidURL
        }
        
        // Prepare request body
        let requestBody = GenerateFlashcardsRequest(
            highlightedText: highlightedText,
            bookTitle: bookTitle,
            count: count
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw AIServiceError.encodingError
        }
        
        // Perform network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse response
        do {
            let flashcards = try JSONDecoder().decode([FlashcardResponse].self, from: data)
            return flashcards.map { $0.toFlashcard(bookId: "", highlightText: highlightedText, userId: "") }
        } catch {
            throw AIServiceError.decodingError
        }
    }
}

// MARK: - Request/Response Models

/// Request model for generating flashcards
private struct GenerateFlashcardsRequest: Codable {
    let highlightedText: String
    let bookTitle: String
    let count: Int
}

/// Response model from Railway API
private struct FlashcardResponse: Codable {
    let question: String
    let answer: String
    
    func toFlashcard(bookId: String = "", highlightText: String = "", userId: String = "") -> Flashcard {
        return Flashcard(
            id: UUID().uuidString,
            question: question,
            answer: answer,
            createdAt: Date(),
            bookId: bookId,
            highlightText: highlightText,
            userId: userId
        )
    }
}

// MARK: - Error Handling

enum AIServiceError: LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode): \(message)"
        case .decodingError:
            return "Failed to parse server response"
        }
    }
}
