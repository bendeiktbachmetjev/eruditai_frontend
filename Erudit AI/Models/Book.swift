//
//  Book.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation

/// Model for book with local storage support
struct Book: Identifiable, Codable {
    let id: String
    let title: String
    let author: String
    let coverUrl: String
    let openedAt: Date
    let filePath: String?
    let fileType: String?
    var lastReadPage: Int
    let thumbnailPath: String?
    
    init(
        id: String,
        title: String,
        author: String,
        coverUrl: String,
        openedAt: Date,
        filePath: String? = nil,
        fileType: String? = nil,
        lastReadPage: Int = 0,
        thumbnailPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverUrl = coverUrl
        self.openedAt = openedAt
        self.filePath = filePath
        self.fileType = fileType
        self.lastReadPage = lastReadPage
        self.thumbnailPath = thumbnailPath
    }
    
    /// Humanized label for when book was opened
    var openedAtLabel: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(openedAt)
        
        if timeInterval >= 86400 { // 1 day
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy"
            return formatter.string(from: openedAt)
        } else if timeInterval >= 3600 { // 1 hour
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval >= 60 { // 1 minute
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
    
    /// Check if book is a PDF
    var isPDF: Bool {
        return fileType?.lowercased() == "pdf"
    }
    
    /// Check if book is an EPUB
    var isEPUB: Bool {
        return fileType?.lowercased() == "epub"
    }
    
    /// Get file extension
    var fileExtension: String? {
        guard let filePath = filePath else { return nil }
        return URL(fileURLWithPath: filePath).pathExtension.lowercased()
    }
}

// MARK: - Core Data Support
extension Book {
    /// Convert to Core Data representation
    func toCoreData() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "author": author,
            "coverUrl": coverUrl,
            "openedAt": openedAt,
            "filePath": filePath ?? "",
            "fileType": fileType ?? "",
            "lastReadPage": lastReadPage,
            "thumbnailPath": thumbnailPath ?? ""
        ]
    }
    
    /// Create from Core Data representation
    static func fromCoreData(data: [String: Any]) -> Book? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let author = data["author"] as? String,
              let coverUrl = data["coverUrl"] as? String,
              let openedAt = data["openedAt"] as? Date else {
            return nil
        }
        
        return Book(
            id: id,
            title: title,
            author: author,
            coverUrl: coverUrl,
            openedAt: openedAt,
            filePath: data["filePath"] as? String,
            fileType: data["fileType"] as? String,
            lastReadPage: data["lastReadPage"] as? Int ?? 0,
            thumbnailPath: data["thumbnailPath"] as? String
        )
    }
}
