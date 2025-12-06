//
//  SimpleFlashcardButton.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

/// Simple floating button for generating flashcards from selected text
struct SimpleFlashcardButton: View {
    let selectedText: String
    let book: Book
    @Binding var isVisible: Bool
    
    @StateObject private var flashcardService = SimpleFlashcardService.shared
    @State private var showingSuccess = false
    
    var body: some View {
        if isVisible && !selectedText.isEmpty {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: generateFlashcard) {
                        HStack(spacing: 8) {
                            if flashcardService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(flashcardService.isLoading ? "Generating..." : "Generate Flashcard")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .disabled(flashcardService.isLoading)
                    
                    Spacer()
                }
                .padding(.bottom, 100) // Above navigation controls
            }
            .alert("Flashcard Generated!", isPresented: $showingSuccess) {
                Button("OK") {
                    isVisible = false
                }
            } message: {
                Text("Your flashcard has been created and saved successfully!")
            }
        }
    }
    
    private func generateFlashcard() {
        Task {
            do {
                _ = try await flashcardService.generateAndSaveFlashcards(
                    highlightedText: selectedText,
                    bookTitle: book.title,
                    bookId: book.id,
                    count: 1 // Generate just one flashcard for simplicity
                )
                
                await MainActor.run {
                    self.showingSuccess = true
                }
            } catch {
                // Error is handled by the service
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        
        SimpleFlashcardButton(
            selectedText: "This is a sample selected text",
            book: Book(
                id: "test",
                title: "Sample Book",
                author: "Test Author",
                coverUrl: "",
                openedAt: Date(),
                filePath: nil,
                fileType: "pdf",
                lastReadPage: 0
            ),
            isVisible: .constant(true)
        )
    }
}

