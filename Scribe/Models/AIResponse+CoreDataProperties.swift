//
//  AIResponse+CoreDataProperties.swift
//  Scribe
//
//  Created by Core Data Generator.
//

import Foundation
import CoreData

extension AIResponse {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AIResponse> {
        return NSFetchRequest<AIResponse>(entityName: "AIResponse")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var model: String?
    @NSManaged public var processingTime: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var tokenUsed: Int32
    @NSManaged public var cell: Cell?

}

extension AIResponse : Identifiable {

}