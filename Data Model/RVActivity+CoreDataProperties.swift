//
//  RVActivity+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVActivity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVActivity> {
        return NSFetchRequest<RVActivity>(entityName: "RVActivity")
    }

    @NSManaged public var id: Int32
    @NSManaged public var name: String?
    @NSManaged public var activityDescription: String?
    @NSManaged public var distance: Double
    @NSManaged public var movingTime: Double
    @NSManaged public var elapsedTime: Double
    @NSManaged public var elevationGain: Double
    @NSManaged public var startDate: NSDate?
    @NSManaged public var timeZone: String?
    @NSManaged public var startLat: Double
    @NSManaged public var startLong: Double
    @NSManaged public var endLat: Double
    @NSManaged public var endLong: Double
    @NSManaged public var averageSpeed: Double
    @NSManaged public var maxSpeed: Double
    @NSManaged public var calories: Double

}
