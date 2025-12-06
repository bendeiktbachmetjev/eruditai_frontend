//
//  FlashCardView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

/// View for studying individual flashcards
struct FlashCardView: View {
    let flashcard: Flashcard
    let onReview: (Int) -> Void // Quality rating (1-5)
    let onSkip: () -> Void
    
    @State private var showingAnswer = false
    @State private var isFlipped = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator
            HStack {
                Text("Repetition \(flashcard.repetitions + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let nextReview = flashcard.nextReview {
                    Text("Next: \(nextReview, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // Flashcard content
            ScrollView {
                VStack(spacing: 20) {
                    // Question - always visible
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        VStack(spacing: 16) {
                            Text("Question")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            Text(flashcard.question)
                                .font(.title3)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .padding(20)
                    }
                    .frame(minHeight: 150)
                    .padding(.horizontal)
                    
                    // Answer card (only visible after showing answer)
                    if showingAnswer {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 16) {
                                Text("Answer")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Text(flashcard.answer)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            .padding(20)
                        }
                        .frame(minHeight: 150)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            Spacer()
            
            // Bottom action area
            VStack(spacing: 12) {
                if !showingAnswer {
                    // Show Answer button
                    Button("Show Answer") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAnswer = true
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                } else {
                    // Review buttons
                    Text("How well did you know this?")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ReviewButton(
                            title: "Again",
                            subtitle: "1",
                            color: .red,
                            action: { onReview(1) }
                        )
                        
                        ReviewButton(
                            title: "Hard",
                            subtitle: "2",
                            color: .orange,
                            action: { onReview(2) }
                        )
                        
                        ReviewButton(
                            title: "Good",
                            subtitle: "3",
                            color: .green,
                            action: { onReview(3) }
                        )
                        
                        ReviewButton(
                            title: "Easy",
                            subtitle: "4",
                            color: .blue,
                            action: { onReview(4) }
                        )
                    }
                    
                    Button("Skip") {
                        onSkip()
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal)
            .transition(.opacity)
        }
        .onChange(of: flashcard.id) { _ in
            // Reset state when flashcard changes
            showingAnswer = false
            isFlipped = false
        }
        .onAppear {
            // Reset state when view first appears
            showingAnswer = false
            isFlipped = false
        }
    }
}

/// Review button component
struct ReviewButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(color)
            .cornerRadius(8)
        }
    }
}

/// Preview for FlashCardView
struct FlashCardView_Preview: View {
    @State private var currentFlashcard: Flashcard
    
    init() {
        _currentFlashcard = State(initialValue: Flashcard(
            id: "preview",
            question: "What is the capital of France?",
            answer: "Paris is the capital and largest city of France. It is located in the north-central part of the country.",
            createdAt: Date(),
            bookId: "book1",
            highlightText: "Paris is the capital and largest city of France, with a population of over 2 million people.",
            userId: "user1",
            easeFactor: 2.3,
            repetitions: 2
        ))
    }
    
    var body: some View {
        FlashCardView(
            flashcard: currentFlashcard,
            onReview: { quality in
                print("Reviewed with quality: \(quality)")
                // Simulate next flashcard
                currentFlashcard = Flashcard(
                    id: "next",
                    question: "What is machine learning?",
                    answer: "Machine learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed.",
                    createdAt: Date(),
                    bookId: "book2",
                    highlightText: "Machine learning algorithms build mathematical models based on training data.",
                    userId: "user1"
                )
            },
            onSkip: {
                print("Skipped flashcard")
            }
        )
    }
}

#Preview {
    FlashCardView_Preview()
}
