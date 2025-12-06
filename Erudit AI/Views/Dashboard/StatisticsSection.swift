//
//  StatisticsSection.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

struct StatisticsSection: View {
    @StateObject private var flashcardService = FlashcardService.shared
    @StateObject private var bookRepository = BookRepository.shared
    @State private var booksCount: Int = 0
    @State private var hoursStudied: Int = 0
    @State private var showingFlashcards = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                DashboardStatCard(
                    label: "Books Read",
                    value: "\(booksCount)",
                    icon: "book.pages",
                    color: .blue
                )
                
                DashboardStatCard(
                    label: "Hours Read",
                    value: "\(hoursStudied)",
                    icon: "clock",
                    color: .green
                )
                
                Button(action: {
                    showingFlashcards = true
                }) {
                    DashboardStatCard(
                        label: "Flashcards Learned",
                        value: "\(flashcardService.statistics.total)",
                        icon: "rectangle.stack",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingFlashcards) {
            FlashCardSectionView()
        }
        .onAppear {
            loadStatistics()
            // Start listening to flashcard updates
            flashcardService.startListeningToFlashcards()
        }
    }
    
    private func loadStatistics() {
        // Load books count from repository
        bookRepository.loadBooks()
        booksCount = bookRepository.books.count
        
        // TODO: Calculate hours studied from reading sessions
        hoursStudied = 0
        
        print("📊 StatisticsSection: Loaded \(booksCount) books")
    }
}

struct DashboardStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(color)
            
            // Value
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StatisticsSection()
        .padding()
}
