//
//  ReviewFlashCardsView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

/// View for reviewing flashcards that are due today
struct ReviewFlashCardsView: View {
    @StateObject private var flashcardService = FlashcardService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var dueFlashcards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCompletion = false
    @State private var reviewedCount = 0
    @State private var skippedCount = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading flashcards...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dueFlashcards.isEmpty {
                EmptyReviewView()
            } else if showingCompletion {
                CompletionView(
                    reviewedCount: reviewedCount,
                    skippedCount: skippedCount,
                    totalCount: dueFlashcards.count
                ) {
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                // Review session
                VStack(spacing: 0) {
                    // Progress header
                    ReviewProgressHeader(
                        currentIndex: currentIndex,
                        totalCount: dueFlashcards.count,
                        reviewedCount: reviewedCount
                    )
                    
                    // Current flashcard
                    FlashCardView(
                        flashcard: dueFlashcards[currentIndex],
                        onReview: { quality in
                            reviewFlashcard(quality: quality)
                        },
                        onSkip: {
                            skipFlashcard()
                        }
                    )
                }
            }
        }
        .navigationTitle("Review Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            if !dueFlashcards.isEmpty && !showingCompletion {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(currentIndex + 1) of \(dueFlashcards.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            loadDueFlashcards()
        }
    }
    
    private func loadDueFlashcards() {
        Task {
            do {
                let flashcards = try await flashcardService.getDueFlashcards()
                await MainActor.run {
                    self.dueFlashcards = flashcards
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func reviewFlashcard(quality: Int) {
        let flashcard = dueFlashcards[currentIndex]
        
        Task {
            do {
                try await flashcardService.updateAfterReview(flashcard.id, quality: quality)
                
                await MainActor.run {
                    reviewedCount += 1
                    moveToNextFlashcard()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func skipFlashcard() {
        skippedCount += 1
        moveToNextFlashcard()
    }
    
    private func moveToNextFlashcard() {
        if currentIndex < dueFlashcards.count - 1 {
            currentIndex += 1
        } else {
            // Review session completed
            showingCompletion = true
        }
    }
}

/// Progress header for review session
struct ReviewProgressHeader: View {
    let currentIndex: Int
    let totalCount: Int
    let reviewedCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: Double(currentIndex + 1), total: Double(totalCount))
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            
            // Stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Reviewed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(reviewedCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
}

/// Empty state when no flashcards are due
struct EmptyReviewView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You have no flashcards due for review today. Great job!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Text("💡 Tip:")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("Highlight text in your books to create new flashcards automatically.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Completion view after review session
struct CompletionView: View {
    let reviewedCount: Int
    let skippedCount: Int
    let totalCount: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Review Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                StatRow(
                    title: "Reviewed",
                    count: reviewedCount,
                    color: .green
                )
                
                StatRow(
                    title: "Skipped",
                    count: skippedCount,
                    color: .orange
                )
                
                StatRow(
                    title: "Total",
                    count: totalCount,
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if reviewedCount > 0 {
                Text("Great job! Your flashcards have been updated with spaced repetition.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Done") {
                onDismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

/// Individual stat row in completion view
struct StatRow: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ReviewFlashCardsView()
}
