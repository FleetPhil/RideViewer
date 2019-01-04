//
//  RVActivity+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVActivity> {
        return NSFetchRequest<RVActivity>(entityName: "RVActivity")
    }

    @NSManaged public var achievementCount: Int16
    @NSManaged public var activityDescription: String?
	@NSManaged public var activityType: String
    @NSManaged public var averageSpeed: Speed
    @NSManaged public var calories: Double
    @NSManaged public var distance: Distance
    @NSManaged public var elapsedTime: Duration
    @NSManaged public var elevationGain: Height
    @NSManaged public var endLat: Double
    @NSManaged public var endLong: Double
    @NSManaged public var id: Int64
    @NSManaged public var kudosCount: Int16
    @NSManaged public var maxSpeed: Speed
    @NSManaged public var movingTime: Duration
    @NSManaged public var name: String
    @NSManaged public var startDate: NSDate
    @NSManaged public var startLat: Double
    @NSManaged public var startLong: Double
    @NSManaged public var timeZone: String
    @NSManaged public var resourceState: ResourceState
	@NSManaged public var kiloJoules : Double
	@NSManaged public var deviceWatts : Bool
	@NSManaged public var trainer : Bool
	@NSManaged public var map : RVMap?

    @NSManaged public var efforts: NSSet
	

}

// MARK: Generated accessors for efforts
extension RVActivity {

    @objc(addEffortsObject:)
    @NSManaged public func addToEfforts(_ value: RVEffort)

    @objc(removeEffortsObject:)
    @NSManaged public func removeFromEfforts(_ value: RVEffort)

    @objc(addEfforts:)
    @NSManaged public func addToEfforts(_ values: NSSet)

    @objc(removeEfforts:)
    @NSManaged public func removeFromEfforts(_ values: NSSet)

}
