//
//  Document+CoreDataProperties.swift
//  
//
//  Created by xinference on 2025/8/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Document {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Document> {
        return NSFetchRequest<Document>(entityName: "Document")
    }

    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var mode: String?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cells: NSSet?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for cells
extension Document {

    @objc(addCellsObject:)
    @NSManaged public func addToCells(_ value: Cell)

    @objc(removeCellsObject:)
    @NSManaged public func removeFromCells(_ value: Cell)

    @objc(addCells:)
    @NSManaged public func addToCells(_ values: NSSet)

    @objc(removeCells:)
    @NSManaged public func removeFromCells(_ values: NSSet)

}

// MARK: Generated accessors for tags
extension Document {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

extension Document : Identifiable {

}
