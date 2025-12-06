//
//  BookService.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import CoreData
import Combine
import FirebaseAuth

/// Service for managing user's books with isolated storage per user
class BookService: ObservableObject {
    static let shared = BookService()
    
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataStack = CoreDataStack.shared
    private let firebaseManager = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Track current user to detect changes
    private var currentUserId: String?
    private var isLoaded = false
    
    private init() {
        setupUserChangeObserver()
    }
    
    // MARK: - User Management
    
    /// Setup observer for user authentication changes
    private func setupUserChangeObserver() {
        firebaseManager.$currentUser
            .sink { [weak self] user in
                let newUserId = user?.uid ?? "guest"
                if self?.currentUserId != newUserId {
                    self?.handleUserChange(newUserId: newUserId)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handle user change - reset cache and load new user's books
    private func handleUserChange(newUserId: String) {
        print("🔄 BookService: User changed from \(currentUserId ?? "nil") to \(newUserId)")
        currentUserId = newUserId
        
        // Reset cache on main thread
        DispatchQueue.main.async { [weak self] in
            self?.resetCache()
            self?.loadBooks()
        }
    }
    
    /// Reset in-memory cache when user changes
    private func resetCache() {
        print("🔄 BookService: Resetting cache - clearing \(books.count) books")
        books.removeAll()
        isLoaded = false
        errorMessage = nil
        print("🔄 BookService: Cache reset complete")
    }
    
    // MARK: - Book Management
    
    /// Get current user ID or 'guest' when not authenticated
    private func getCurrentUserId() -> String {
        return firebaseManager.currentUser?.uid ?? "guest"
    }
    
    /// Load books for current user
    func loadBooks() {
        guard !isLoaded else { 
            print("📚 BookService: Books already loaded, skipping")
            return 
        }
        
        isLoading = true
        errorMessage = nil
        
        let userId = getCurrentUserId()
        print("📚 BookService: Loading books for user: \(userId)")
        
        // Try Core Data first
        do {
            let context = coreDataStack.context
            let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \BookEntity.openedAt, ascending: false)]
            
            let entities = try context.fetch(request)
            var loadedBooks = entities.map { $0.toBook() }
            
            print("📚 BookService: Found \(entities.count) entities in Core Data for user \(userId)")
            
            // Validate file paths and remove orphaned books
            var orphanedEntities: [BookEntity] = []
            loadedBooks = loadedBooks.filter { book in
                if let filePath = book.filePath, !filePath.isEmpty {
                    let fileExists = FileManager.default.fileExists(atPath: filePath)
                    if !fileExists {
                        print("⚠️ BookService: Found orphaned book '\(book.title)' - file missing at: \(filePath)")
                        if let entity = entities.first(where: { $0.id == book.id }) {
                            orphanedEntities.append(entity)
                        }
                        return false
                    }
                    return true
                } else {
                    // Book without file path - might be valid for some cases, but log it
                    print("⚠️ BookService: Book '\(book.title)' has no file path")
                    return true
                }
            }
            
            // Remove orphaned entities from Core Data
            if !orphanedEntities.isEmpty {
                print("📚 BookService: Removing \(orphanedEntities.count) orphaned books from Core Data")
                for entity in orphanedEntities {
                    context.delete(entity)
                }
                try? context.save()
            }
            
            // Set initial state immediately
            DispatchQueue.main.async { [weak self] in
                self?.books = loadedBooks
                self?.isLoading = false
                self?.isLoaded = true
                print("✅ BookService: Loaded \(loadedBooks.count) initial books from Core Data for user \(userId)")
            }
            
            // Recover books from file system that are not in Core Data (async operation)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let recoveredBooks = await self.recoverBooksFromFileSystem(userId: userId, existingBooks: loadedBooks)
                
                if !recoveredBooks.isEmpty {
                    print("📚 BookService: Recovered \(recoveredBooks.count) books from file system")
                    // Save recovered books to Core Data
                    for book in recoveredBooks {
                        try? await self.saveBook(book)
                    }
                    // Update books array with recovered books
                    var updatedBooks = self.books
                    updatedBooks.append(contentsOf: recoveredBooks)
                    self.books = updatedBooks
                    print("✅ BookService: Updated books list with \(recoveredBooks.count) recovered books")
                    print("📚 BookService: Total books now: \(updatedBooks.count)")
                }
            }
        } catch {
            print("❌ Core Data failed, trying fallback: \(error)")
            // Fallback to empty list for now
            DispatchQueue.main.async { [weak self] in
                self?.books = []
                self?.isLoading = false
                self?.isLoaded = true
                self?.errorMessage = "Core Data unavailable, using fallback"
                print("⚠️ BookService: Using fallback mode for user \(userId)")
            }
        }
    }
    
    /// Get recently opened books
    func getRecentlyOpened() -> [Book] {
        if !isLoaded {
            loadBooks()
        }
        return books.sorted { $0.openedAt > $1.openedAt }
    }
    
    /// Add a new book
    func addBook(filePath: String) async throws -> Book {
        let userId = getCurrentUserId()
        let fileName = URL(fileURLWithPath: filePath).lastPathComponent
        let fileExtension = URL(fileURLWithPath: filePath).pathExtension.lowercased()
        
        print("📚 BookService: Adding book - fileName: \(fileName), extension: \(fileExtension), userId: \(userId)")
        
        guard ["pdf", "epub"].contains(fileExtension) else {
            throw BookServiceError.unsupportedFileType(fileExtension)
        }
        
        // Prepare target path to check
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let userDir = documentsPath.appendingPathComponent(userId)
        let booksDir = userDir.appendingPathComponent("books")
        let targetPath = booksDir.appendingPathComponent(fileName)
        
        // Check if book already exists in Core Data (by file name and file existence)
        let existingBook = books.first { book in
            let bookFileName = URL(fileURLWithPath: book.filePath ?? "").lastPathComponent
            let fileExists = book.filePath != nil && FileManager.default.fileExists(atPath: book.filePath!)
            return bookFileName == fileName && fileExists
        }
        
        // Also check if file exists in target directory (might be in file system but not in Core Data)
        let fileExistsInTargetDir = FileManager.default.fileExists(atPath: targetPath.path)
        
        if let existingBook = existingBook {
            print("📚 BookService: Book already exists in library: \(existingBook.title)")
            throw BookServiceError.bookAlreadyExists(existingBook.title)
        }
        
        if fileExistsInTargetDir {
            // File exists in target directory - check if it's in Core Data
            let context = coreDataStack.context
            let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            request.predicate = NSPredicate(format: "filePath == %@ AND userId == %@", targetPath.path, userId)
            
            if let existingEntity = try? context.fetch(request).first {
                // File exists and is in Core Data - restore it to books array
                let restoredBook = existingEntity.toBook()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let bookExists = self.books.contains(where: { $0.id == restoredBook.id })
                    if !bookExists {
                        self.books.insert(restoredBook, at: 0)
                    }
                }
                print("📚 BookService: Book already exists in Core Data: \(restoredBook.title)")
                throw BookServiceError.bookAlreadyExists(restoredBook.title)
            } else {
                // File exists but not in Core Data - remove it to replace with new one
                print("📚 BookService: File exists at target but not in Core Data, removing: \(targetPath.path)")
                try? FileManager.default.removeItem(at: targetPath)
            }
        }
        
        // Remove orphaned books (books with same name but missing files)
        let orphanedBooks = books.filter { book in
            let bookFileName = URL(fileURLWithPath: book.filePath ?? "").lastPathComponent
            let fileMissing = book.filePath == nil || !FileManager.default.fileExists(atPath: book.filePath!)
            return bookFileName == fileName && fileMissing
        }
        
        for orphanedBook in orphanedBooks {
            print("📚 BookService: Removing orphaned book: \(orphanedBook.title)")
            try? await removeBook(bookId: orphanedBook.id)
        }
        
        // Copy file to app documents directory (booksDir and targetPath already defined above)
        print("📚 BookService: Creating directory at: \(booksDir.path)")
        try FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)
        
        print("📚 BookService: Copying from \(filePath) to \(targetPath.path)")
        
        // Use URL for security-scoped resources
        let sourceURL = URL(fileURLWithPath: filePath)
        
        // Check if source and target are the same file
        if sourceURL.path == targetPath.path {
            print("📚 BookService: Source and target are the same, skipping copy")
        } else {
            try FileManager.default.copyItem(at: sourceURL, to: targetPath)
        }
        
        let book = Book(
            id: UUID().uuidString,
            title: extractTitleFromFileName(fileName),
            author: "Unknown Author",
            coverUrl: "",
            openedAt: Date(),
            filePath: targetPath.path,
            fileType: fileExtension
        )
        
        print("📚 BookService: Created book object: \(book.title) (ID: \(book.id))")
        
        try await saveBook(book)
        
        DispatchQueue.main.async { [weak self] in
            self?.books.insert(book, at: 0)
            print("📚 BookService: Added book to in-memory array. Total books: \(self?.books.count ?? 0)")
        }
        
        return book
    }
    
    /// Save book to Core Data
    private func saveBook(_ book: Book) async throws {
        do {
            let context = coreDataStack.context
            let entity = BookEntity(context: context)
            entity.updateFromBook(book)
            entity.userId = getCurrentUserId()
            
            try context.save()
            print("✅ BookService: Saved book to Core Data")
        } catch {
            print("❌ BookService: Failed to save to Core Data: \(error)")
            // For now, just add to in-memory array as fallback
            DispatchQueue.main.async { [weak self] in
                self?.books.insert(book, at: 0)
            }
        }
    }
    
    /// Remove a book
    func removeBook(bookId: String) async throws {
        let userId = getCurrentUserId()
        let context = coreDataStack.context
        
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@", bookId, userId)
        
        let entities = try context.fetch(request)
        
        for entity in entities {
            // Remove physical file if it exists
            if let filePath = entity.filePath, !filePath.isEmpty {
                try? FileManager.default.removeItem(atPath: filePath)
            }
            
            // Remove thumbnail if it exists
            if let thumbnailPath = entity.thumbnailPath, !thumbnailPath.isEmpty {
                try? FileManager.default.removeItem(atPath: thumbnailPath)
            }
            
            context.delete(entity)
        }
        
        try context.save()
        
        DispatchQueue.main.async { [weak self] in
            self?.books.removeAll { $0.id == bookId }
        }
    }
    
    /// Update last opened time
    func updateLastOpened(bookId: String) async throws {
        let userId = getCurrentUserId()
        let context = coreDataStack.context
        
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@", bookId, userId)
        
        let entities = try context.fetch(request)
        
        for entity in entities {
            entity.openedAt = Date()
        }
        
        try context.save()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.books.firstIndex(where: { $0.id == bookId }) {
                let currentBook = self.books[index]
                let updatedBook = Book(
                    id: currentBook.id,
                    title: currentBook.title,
                    author: currentBook.author,
                    coverUrl: currentBook.coverUrl,
                    openedAt: Date(),
                    filePath: currentBook.filePath,
                    fileType: currentBook.fileType,
                    lastReadPage: currentBook.lastReadPage,
                    thumbnailPath: currentBook.thumbnailPath
                )
                self.books[index] = updatedBook
            }
        }
    }
    
    /// Update last read page
    func updateLastReadPage(bookId: String, pageNumber: Int) async throws {
        let userId = getCurrentUserId()
        let context = coreDataStack.context
        
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@", bookId, userId)
        
        let entities = try context.fetch(request)
        
        for entity in entities {
            entity.lastReadPage = Int32(pageNumber)
        }
        
        try context.save()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.books.firstIndex(where: { $0.id == bookId }) {
                let currentBook = self.books[index]
                let updatedBook = Book(
                    id: currentBook.id,
                    title: currentBook.title,
                    author: currentBook.author,
                    coverUrl: currentBook.coverUrl,
                    openedAt: currentBook.openedAt,
                    filePath: currentBook.filePath,
                    fileType: currentBook.fileType,
                    lastReadPage: pageNumber,
                    thumbnailPath: currentBook.thumbnailPath
                )
                self.books[index] = updatedBook
            }
        }
    }
    
    /// Update thumbnail path
    func updateThumbnailPath(bookId: String, thumbnailPath: String?) async throws {
        let userId = getCurrentUserId()
        let context = coreDataStack.context
        
        let request: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND userId == %@", bookId, userId)
        
        let entities = try context.fetch(request)
        
        for entity in entities {
            entity.thumbnailPath = thumbnailPath
        }
        
        try context.save()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.books.firstIndex(where: { $0.id == bookId }) {
                let currentBook = self.books[index]
                let updatedBook = Book(
                    id: currentBook.id,
                    title: currentBook.title,
                    author: currentBook.author,
                    coverUrl: currentBook.coverUrl,
                    openedAt: currentBook.openedAt,
                    filePath: currentBook.filePath,
                    fileType: currentBook.fileType,
                    lastReadPage: currentBook.lastReadPage,
                    thumbnailPath: thumbnailPath
                )
                self.books[index] = updatedBook
            }
        }
    }
    
    /// Recover books from file system that are not in Core Data
    private func recoverBooksFromFileSystem(userId: String, existingBooks: [Book]) async -> [Book] {
        var recoveredBooks: [Book] = []
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let userDir = documentsPath.appendingPathComponent(userId)
        let booksDir = userDir.appendingPathComponent("books")
        
        // Check if books directory exists
        guard FileManager.default.fileExists(atPath: booksDir.path) else {
            print("📚 BookService: Books directory does not exist: \(booksDir.path)")
            return recoveredBooks
        }
        
        // Get all files in books directory
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: booksDir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("📚 BookService: Failed to read contents of books directory")
            return recoveredBooks
        }
        
        // Get existing file paths from Core Data
        let existingFilePaths = Set(existingBooks.compactMap { $0.filePath })
        
        // Process each file
        for fileURL in fileURLs {
            // Check if it's a regular file (not a directory)
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
               let isRegularFile = resourceValues.isRegularFile {
                if !isRegularFile {
                    continue
                }
            }
            
            let filePath = fileURL.path
            let fileName = fileURL.lastPathComponent
            let fileExtension = fileURL.pathExtension.lowercased()
            
            // Skip if not a book file
            guard ["pdf", "epub"].contains(fileExtension) else {
                continue
            }
            
            // Skip if already in existing books
            if existingFilePaths.contains(filePath) {
                continue
            }
            
            // Check if file is readable
            guard FileManager.default.isReadableFile(atPath: filePath) else {
                print("⚠️ BookService: File is not readable: \(filePath)")
                continue
            }
            
            // Create book object from file
            let book = Book(
                id: UUID().uuidString,
                title: extractTitleFromFileName(fileName),
                author: "Unknown Author",
                coverUrl: "",
                openedAt: Date(),
                filePath: filePath,
                fileType: fileExtension
            )
            
            recoveredBooks.append(book)
            print("📚 BookService: Recovered book '\(book.title)' from file system: \(filePath)")
        }
        
        return recoveredBooks
    }
    
    /// Extract title from file name
    private func extractTitleFromFileName(_ fileName: String) -> String {
        let nameWithoutExt = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        return nameWithoutExt
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

// MARK: - Errors

enum BookServiceError: LocalizedError {
    case unsupportedFileType(String)
    case bookNotFound(String)
    case saveFailed(String)
    case bookAlreadyExists(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type). Only PDF and EPUB files are supported."
        case .bookNotFound(let id):
            return "Book with ID \(id) not found."
        case .saveFailed(let reason):
            return "Failed to save book: \(reason)"
        case .bookAlreadyExists(let title):
            return "Book '\(title)' already exists in your library."
        }
    }
}
