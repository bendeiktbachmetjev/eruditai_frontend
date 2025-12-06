//
//  BookRepository.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import CoreData
import FirebaseAuth
import Combine

/// Repository for managing user's books with isolated storage per user
class BookRepository: ObservableObject {
    static let shared = BookRepository()
    
    private let bookService = BookService.shared
    
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    /// Setup observers for BookService
    private func setupObservers() {
        bookService.$books
            .assign(to: \.books, on: self)
            .store(in: &cancellables)
        
        bookService.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
        
        bookService.$errorMessage
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    /// Load books from BookService
    func loadBooks() {
        bookService.loadBooks()
    }
    
    /// Get recently opened books
    func getRecentlyOpened() -> [Book] {
        return bookService.getRecentlyOpened()
    }
    
    /// Add a new book from file path
    func addBook(filePath: String) async throws -> Book {
        return try await bookService.addBook(filePath: filePath)
    }
    
    /// Remove a book
    func removeBook(id: String) async throws {
        try await bookService.removeBook(bookId: id)
    }
    
    /// Update last opened time
    func updateLastOpened(id: String) async throws {
        try await bookService.updateLastOpened(bookId: id)
    }
    
    /// Update last read page
    func updateLastReadPage(id: String, page: Int) async throws {
        try await bookService.updateLastReadPage(bookId: id, pageNumber: page)
    }
    
    /// Update thumbnail path
    func updateThumbnailPath(id: String, thumbnailPath: String?) async throws {
        try await bookService.updateThumbnailPath(bookId: id, thumbnailPath: thumbnailPath)
    }
    
    /// Get book by ID
    func getBook(id: String) -> Book? {
        return books.first { $0.id == id }
    }
    
    /// Check if book exists
    func bookExists(id: String) -> Bool {
        return getBook(id: id) != nil
    }
}
