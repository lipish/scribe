//
//  Cell+CoreDataProperties.swift
//  
//
//  Created by xinference on 2025/8/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Cell {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Cell> {
        return NSFetchRequest<Cell>(entityName: "Cell")
    }

    @NSManaged public var cellType: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var input: String?
    @NSManaged public var orderIndex: Int32
    @NSManaged public var output: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var aiResponses: NSSet?
    @NSManaged public var document: Document?

}

// MARK: Generated accessors for aiResponses
extension Cell {

    @objc(addAiResponsesObject:)
    @NSManaged public func addToAiResponses(_ value: AIResponse)

    @objc(removeAiResponsesObject:)
    @NSManaged public func removeFromAiResponses(_ value: AIResponse)

    @objc(addAiResponses:)
    @NSManaged public func addToAiResponses(_ values: NSSet)

    @objc(removeAiResponses:)
    @NSManaged public func removeFromAiResponses(_ values: NSSet)

}

extension Cell : Identifiable {

}
