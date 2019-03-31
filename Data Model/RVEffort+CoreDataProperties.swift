//
//  RVEffort+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVEffort {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVEffort> {
        return NSFetchRequest<RVEffort>(entityName: "RVEffort")
    }

    @NSManaged public var resourceState: RVResourceState
    @NSManaged public var id: Int64
    @NSManaged public var elapsedTime: Duration
    @NSManaged public var name: String?
    @NSManaged public var movingTime: Duration
    @NSManaged public var startDate: NSDate
    @NSManaged public var distance: Distance
    @NSManaged public var averageCadence: Double
    @NSManaged public var averageWatts: Double
    @NSManaged public var averageHeartRate: Double
	@NSManaged public var averageSpeed: Speed
    @NSManaged public var maxHeartRate: Double
    @NSManaged public var komRank: Int16
    @NSManaged public var prRank: Int16
	@NSManaged public var startIndex: Int64
	@NSManaged public var endIndex: Int64
	@NSManaged public var photoScanDate : NSDate?
    @NSManaged public var segment: RVSegment
    @NSManaged public var activity: RVActivity
	@NSManaged public var streams: Set<RVStream>

}
