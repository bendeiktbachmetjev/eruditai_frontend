//
//  ReaderView.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 20/01/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ReaderView: View {
    @StateObject private var bookRepository = BookRepository.shared
    @State private var showingFilePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Add book button - positioned to the left
                HStack {
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Books")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                    Spacer()
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Books library
                if bookRepository.isLoading {
                    Spacer()
                    ProgressView("Loading your books...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if bookRepository.books.isEmpty {
                    EmptyLibraryView()
                } else {
                    BooksLibraryView(books: bookRepository.books)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.pdf, UTType.epub],
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result: result)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            bookRepository.loadBooks()
        }
    }
    
    private func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                for url in urls {
                    // Start accessing security-scoped resource
                    let isAccessing = url.startAccessingSecurityScopedResource()
                    
                    defer {
                        if isAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    do {
                        // Copy file while we have access
                        _ = try await bookRepository.addBook(filePath: url.path)
                    } catch {
                        DispatchQueue.main.async {
                            errorMessage = "Failed to add book: \(error.localizedDescription)"
                            showingError = true
                        }
                    }
                }
            }
        case .failure(let error):
            errorMessage = "Failed to select files: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Supporting Views

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Your Library is Empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first book to start reading")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BooksLibraryView: View {
    let books: [Book]
    @State private var searchText = ""
    @State private var selectedBook: Book?
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search books...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Books list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredBooks) { book in
                        BookSheetView(book: book, onTap: {
                            selectedBook = book
                        })
                    }
                }
                .padding(.bottom, 20)
            }
            .fullScreenCover(item: $selectedBook) { book in
                NavigationView {
                    BookReaderView(book: book)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedBook = nil
                                }
                            }
                        }
                }
            }
        }
    }
}

struct BookSheetView: View {
    let book: Book
    let onTap: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover/sheet representation - A4 format for PDF
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                book.fileType == "epub" ? .blue : .green,
                                book.fileType == "epub" ? .blue.opacity(0.7) : .green.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 100) // A4 ratio: 7:10
                
                VStack(spacing: 4) {
                    Image(systemName: book.fileType == "epub" ? "book.fill" : "doc.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text(book.fileType?.uppercased() ?? "BOOK")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .overlay(
                // Delete button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .background(Color.white, in: Circle())
                        }
                    }
                    Spacer()
                }
                .padding(6)
            )
            
            // Book info - positioned to the right
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if !book.author.isEmpty && book.author != "Unknown Author" {
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Last opened info
                Text("Opened \(formatDate(book.openedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
        .alert("Delete Book", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await BookRepository.shared.removeBook(id: book.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(book.title)'? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    ReaderView()
}
