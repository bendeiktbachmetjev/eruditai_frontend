//
//  BookTestView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

/// Test view for BookService functionality
struct BookTestView: View {
    @StateObject private var bookRepository = BookRepository.shared
    @State private var showingFilePicker = false
    @State private var selectedFileURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Book Service Test")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Testing isolated storage per user")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Add Book Button
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Book")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
                
                // Loading indicator
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                }
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Books list
                if bookRepository.books.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No books yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add a PDF or EPUB file to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(bookRepository.books) { book in
                            BookRowView(book: book)
                        }
                        .onDelete(perform: deleteBooks)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Books")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.pdf, UTType.epub],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result: result)
        }
        .onAppear {
            bookRepository.loadBooks()
        }
    }
    
    /// Handle file selection from file picker
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            selectedFileURL = url
            addBook(from: url)
        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
        }
    }
    
    /// Add book from file URL
    private func addBook(from url: URL) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Start accessing security-scoped resource
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                
                let book = try await bookRepository.addBook(filePath: url.path)
                print("✅ Successfully added book: \(book.title)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to add book: \(error.localizedDescription)"
                    print("❌ Error adding book: \(error)")
                }
            }
        }
    }
    
    /// Delete books
    private func deleteBooks(offsets: IndexSet) {
        Task {
            for index in offsets {
                let book = bookRepository.books[index]
                do {
                    try await bookRepository.removeBook(id: book.id)
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to delete book: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

/// Row view for displaying a book
struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // Book icon
            Image(systemName: book.isPDF ? "doc.text" : "book.closed")
                .font(.title2)
                .foregroundColor(book.isPDF ? .red : .blue)
                .frame(width: 30)
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(book.openedAtLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if book.lastReadPage > 0 {
                        Text("Page \(book.lastReadPage)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookTestView()
}
