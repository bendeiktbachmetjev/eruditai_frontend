//
//  BookEntity+CoreDataClass.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import CoreData

@objc(BookEntity)
public class BookEntity: NSManagedObject {
    
    /// Convert to Book model
    func toBook() -> Book {
        return Book(
            id: id ?? "",
            title: title ?? "",
            author: author ?? "",
            coverUrl: coverUrl ?? "",
            openedAt: openedAt ?? Date(),
            filePath: filePath,
            fileType: fileType,
            lastReadPage: Int(lastReadPage),
            thumbnailPath: thumbnailPath
        )
    }
    
    /// Update from Book model
    func updateFromBook(_ book: Book) {
        self.id = book.id
        self.title = book.title
        self.author = book.author
        self.coverUrl = book.coverUrl
        self.openedAt = book.openedAt
        self.filePath = book.filePath
        self.fileType = book.fileType
        self.lastReadPage = Int32(book.lastReadPage)
        self.thumbnailPath = book.thumbnailPath
    }
}
