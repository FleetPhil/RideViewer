//
//  RVSegment+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVSegment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVSegment> {
        return NSFetchRequest<RVSegment>(entityName: "RVSegment")
    }

    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var resourceState: ResourceState
    @NSManaged public var distance: Distance
    @NSManaged public var averageGrade: Double
    @NSManaged public var maxGrade: Double
    @NSManaged public var maxElevation: Height
    @NSManaged public var minElevation: Height
    @NSManaged public var startLat: Double
    @NSManaged public var endLat: Double
    @NSManaged public var startLong: Double
    @NSManaged public var endLong: Double
    @NSManaged public var climbCategory: Int16
    @NSManaged public var elevationGain: Height
    @NSManaged public var starred: Bool
    @NSManaged public var effortCount: Int64
    @NSManaged public var athleteCount: Int64
    @NSManaged public var efforts: NSSet

}

// MARK: Generated accessors for efforts
extension RVSegment {

    @objc(addEffortsObject:)
    @NSManaged public func addToEfforts(_ value: RVEffort)

    @objc(removeEffortsObject:)
    @NSManaged public func removeFromEfforts(_ value: RVEffort)

    @objc(addEfforts:)
    @NSManaged public func addToEfforts(_ values: NSSet)

    @objc(removeEfforts:)
    @NSManaged public func removeFromEfforts(_ values: NSSet)

}
