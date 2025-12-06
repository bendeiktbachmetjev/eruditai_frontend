//
//  BookEntity+CoreDataProperties.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import CoreData

extension BookEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookEntity> {
        return NSFetchRequest<BookEntity>(entityName: "BookEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var coverUrl: String?
    @NSManaged public var openedAt: Date?
    @NSManaged public var filePath: String?
    @NSManaged public var fileType: String?
    @NSManaged public var lastReadPage: Int32
    @NSManaged public var thumbnailPath: String?
    @NSManaged public var userId: String?

}

extension BookEntity : Identifiable {

}
