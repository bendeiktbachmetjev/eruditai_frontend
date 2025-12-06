//
//  AITestView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import SwiftUI

/// Test view for AIService functionality
struct AITestView: View {
    @StateObject private var aiService = AIService.shared
    @State private var highlightedText = "The mitochondria is the powerhouse of the cell. It produces ATP through cellular respiration."
    @State private var bookTitle = "Biology Textbook"
    @State private var count = 3
    @State private var generatedFlashcards: [Flashcard] = []
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("AI Service Test")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Testing Railway API integration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Test connection button
                    Button(action: testConnection) {
                        HStack {
                            Image(systemName: "wifi")
                            Text("Test Connection")
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(aiService.isLoading)
                    
                    // Input fields
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Highlighted Text")
                            .font(.headline)
                        
                        TextEditor(text: $highlightedText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Book Title")
                                .font(.headline)
                            TextField("Enter book title", text: $bookTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Count")
                                .font(.headline)
                            Stepper(value: $count, in: 1...10) {
                                Text("\(count)")
                            }
                        }
                    }
                    
                    // Generate flashcards button
                    Button(action: generateFlashcards) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Generate Flashcards")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(aiService.isLoading || highlightedText.isEmpty)
                    
                    // Loading indicator
                    if aiService.isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Generating flashcards...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Error message
                    if let errorMessage = aiService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Results
                    if !generatedFlashcards.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Generated Flashcards")
                                .font(.headline)
                            
                            ForEach(Array(generatedFlashcards.enumerated()), id: \.offset) { index, flashcard in
                                FlashcardTestRow(flashcard: flashcard, index: index + 1)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("AI Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    /// Test API connection
    private func testConnection() {
        Task {
            let isConnected = await aiService.testConnection()
            await MainActor.run {
                if isConnected {
                    // Show success message
                    print("✅ AI Service connection successful")
                } else {
                    print("❌ AI Service connection failed")
                }
            }
        }
    }
    
    /// Generate flashcards using AIService
    private func generateFlashcards() {
        Task {
            do {
                let flashcards = try await aiService.generateFlashcards(
                    highlightedText: highlightedText,
                    bookTitle: bookTitle,
                    count: count
                )
                
                await MainActor.run {
                    generatedFlashcards = flashcards
                    showingResults = true
                    print("✅ Generated \(flashcards.count) flashcards")
                }
            } catch {
                await MainActor.run {
                    print("❌ Error generating flashcards: \(error)")
                }
            }
        }
    }
}

/// Row view for displaying a flashcard in test
struct FlashcardTestRow: View {
    let flashcard: Flashcard
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(index).")
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Question:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(flashcard.question)
                    .font(.body)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Answer:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(flashcard.answer)
                    .font(.body)
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    AITestView()
}
