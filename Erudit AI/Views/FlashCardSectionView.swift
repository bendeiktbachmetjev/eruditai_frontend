//
//  FlashCardSectionView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

/// Main view for managing flashcards - shows all user's flashcards
struct FlashCardSectionView: View {
    @StateObject private var flashcardService = FlashcardService.shared
    @StateObject private var simpleFlashcardService = SimpleFlashcardService.shared
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddFlashcard = false
    @State private var selectedFlashcard: Flashcard?
    @State private var showingEditView = false
    @State private var showingReviewView = false
    
    // Use published flashcards from service instead of local state
    private var flashcards: [Flashcard] {
        flashcardService.flashcards
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with statistics
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Flashcards")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(flashcards.count) total flashcards")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddFlashcard = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                // Statistics cards
                HStack(spacing: 12) {
                    StatCard(
                        title: "Due Today",
                        count: flashcardService.statistics.due,
                        color: .orange
                    )
                    
                    StatCard(
                        title: "New",
                        count: flashcardService.statistics.new,
                        color: .green
                    )
                    
                    StatCard(
                        title: "Total",
                        count: flashcardService.statistics.total,
                        color: .blue
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Flashcards list
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading flashcards...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if flashcards.isEmpty && !isLoading {
                EmptyFlashcardsView()
            } else if flashcards.isEmpty && isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading flashcards...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(flashcards) { flashcard in
                        FlashCardRowView(flashcard: flashcard) {
                            selectedFlashcard = flashcard
                            showingEditView = true
                        }
                    }
                    .onDelete(perform: deleteFlashcards)
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    loadFlashcards()
                }
            }
        }
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Review") {
                    showingReviewView = true
                }
                .foregroundColor(.blue)
                .disabled(flashcardService.statistics.due == 0)
            }
        }
        .onAppear {
            loadFlashcards()
            // Start listening to real-time updates
            flashcardService.startListeningToFlashcards()
            flashcardService.startListeningToDueFlashcards()
        }
        .onDisappear {
            // Stop listening when leaving the view to save resources
            flashcardService.stopListening()
        }
        .sheet(isPresented: $showingAddFlashcard) {
            FlashCardEditView(flashcard: nil) { newFlashcard in
                addFlashcard(newFlashcard)
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let flashcard = selectedFlashcard {
                FlashCardEditView(flashcard: flashcard) { updatedFlashcard in
                    updateFlashcard(updatedFlashcard)
                }
            }
        }
        .fullScreenCover(isPresented: $showingReviewView) {
            ReviewFlashCardsView()
        }
    }
    
    private func loadFlashcards() {
        // Real-time listener handles the data loading
        // Just manage loading state
        isLoading = false
    }
    
    private func addFlashcard(_ flashcard: Flashcard) {
        Task {
            do {
                _ = try await flashcardService.addFlashcard(flashcard)
                // Real-time listener will automatically update the flashcards
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateFlashcard(_ flashcard: Flashcard) {
        Task {
            do {
                try await flashcardService.updateFlashcard(flashcard)
                // Real-time listener will automatically update the flashcards
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteFlashcards(offsets: IndexSet) {
        Task {
            for index in offsets {
                let flashcard = flashcards[index]
                do {
                    try await flashcardService.deleteFlashcard(flashcard.id)
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
            // Real-time listener will automatically update the flashcards
        }
    }
}

/// Statistics card component
struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Individual flashcard row in the list
struct FlashCardRowView: View {
    let flashcard: Flashcard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(flashcard.question)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(flashcard.answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(flashcard.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if flashcard.isDue {
                        Text("Due")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text("\(flashcard.repetitions) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Empty state view when no flashcards exist
struct EmptyFlashcardsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Flashcards Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by highlighting text in your books to create flashcards automatically, or add them manually.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Add Your First Flashcard") {
                // This will be handled by the parent view
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FlashCardSectionView()
}
