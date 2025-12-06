//
//  RecentlyOpenedSection.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI

struct RecentlyOpenedSection: View {
    @StateObject private var bookRepository = BookRepository.shared
    @State private var selectedBook: Book?
    
    // Compute recently opened from published books to avoid side-effects during view updates
    private var recentlyOpened: [Book] {
        Array(bookRepository.books.sorted { $0.openedAt > $1.openedAt }.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recently Opened")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !recentlyOpened.isEmpty {
                    Button("See All") {
                        // TODO: Navigate to full library
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Dynamic height container that adapts to available space
            GeometryReader { geometry in
                ZStack {
                    if bookRepository.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Spacer()
                        }
                    } else if recentlyOpened.isEmpty {
                        EmptyStateView()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recentlyOpened) { book in
                                    BookCard(book: book, availableHeight: geometry.size.height) {
                                        selectedBook = book
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
        // Load books asynchronously outside the view-update phase
        .task {
            bookRepository.loadBooks()
        }
        .fullScreenCover(item: $selectedBook) { book in
            NavigationView {
                BookReaderView(book: book)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                selectedBook = nil
                                // Update last opened time; repository will publish changes
                                Task {
                                    try? await bookRepository.updateLastOpened(id: book.id)
                                }
                            }
                        }
                    }
            }
        }
    }
}

struct BookCard: View {
    let book: Book
    let availableHeight: CGFloat
    let onTap: () -> Void
    
    // Calculate optimal card size based on available height
    private var cardHeight: CGFloat {
        // Reserve space for text below the cover (about 60-80 points)
        let textSpace: CGFloat = 80
        return max(availableHeight - textSpace, 200) // Increased minimum to 200 points
    }
    
    private var cardWidth: CGFloat {
        // Maintain book-like aspect ratio (roughly 3:4)
        return cardHeight * 0.7
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Book cover
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [book.fileType == "epub" ? .blue : .green],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: cardWidth, height: cardHeight)
                
                VStack(spacing: 6) {
                    Image(systemName: book.fileType == "epub" ? "book.fill" : "doc.fill")
                        .font(.system(size: min(cardHeight * 0.2, 40))) // Scale icon with card size
                        .foregroundColor(.white)
                    
                    Text(book.fileType?.uppercased() ?? "BOOK")
                        .font(.system(size: min(cardHeight * 0.08, 12)))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: min(cardHeight * 0.08, 14)))
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.system(size: min(cardHeight * 0.07, 12)))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(book.openedAtLabel)
                    .font(.system(size: min(cardHeight * 0.07, 12)))
                    .foregroundColor(.secondary)
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No recently opened books")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Start reading to see your books here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    RecentlyOpenedSection()
        .padding()
}
