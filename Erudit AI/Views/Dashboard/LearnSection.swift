//
//  LearnSection.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

struct LearnSection: View {
    @StateObject private var flashcardService = FlashcardService.shared
    @State private var showingReviewView = false
    
    var body: some View {
        Button(action: {
            showingReviewView = true
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review Flash Cards")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if flashcardService.statistics.due == 0 {
                        Text("No flashcards due today")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("\(flashcardService.statistics.due) flashcard\(flashcardService.statistics.due != 1 ? "s" : "") to review today")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Arrow
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0/255, green: 122/255, blue: 255/255), // #007AFF
                                Color(red: 123/255, green: 97/255, blue: 255/255), // #7B61FF
                                Color(red: 255/255, green: 138/255, blue: 52/255)  // #FF8A34
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingReviewView) {
            ReviewFlashCardsView()
        }
        .onAppear {
            // Start listening to flashcard updates
            flashcardService.startListeningToFlashcards()
            flashcardService.startListeningToDueFlashcards()
        }
    }
}

#Preview {
    LearnSection()
        .padding()
}
