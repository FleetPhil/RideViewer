//
//  RVMap+CoreDataProperties.swift
//  RideViewer
//
//  Created by Phil Diggens on 31/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVMap {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVMap> {
        return NSFetchRequest<RVMap>(entityName: "RVMap")
    }

    @NSManaged public var resourceState: ResourceState
    @NSManaged public var id: String
    @NSManaged public var polyline: String?
    @NSManaged public var summaryPolyline: String?
    @NSManaged public var activities: NSSet?
    @NSManaged public var segments: NSSet?

}

// MARK: Generated accessors for activities
extension RVMap {

    @objc(addActivitiesObject:)
    @NSManaged public func addToActivities(_ value: RVActivity)

    @objc(removeActivitiesObject:)
    @NSManaged public func removeFromActivities(_ value: RVActivity)

    @objc(addActivities:)
    @NSManaged public func addToActivities(_ values: NSSet)

    @objc(removeActivities:)
    @NSManaged public func removeFromActivities(_ values: NSSet)

}

// MARK: Generated accessors for segments
extension RVMap {

    @objc(addSegmentsObject:)
    @NSManaged public func addToSegments(_ value: RVSegment)

    @objc(removeSegmentsObject:)
    @NSManaged public func removeFromSegments(_ value: RVSegment)

    @objc(addSegments:)
    @NSManaged public func addToSegments(_ values: NSSet)

    @objc(removeSegments:)
    @NSManaged public func removeFromSegments(_ values: NSSet)

}
