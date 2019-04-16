//
//  RVStream+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 25/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVStream {
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<RVStream> {
		return NSFetchRequest<RVStream>(entityName: "RVStream")
	}
	
	@NSManaged public var stravaType: String		// Use enum accessor 'type'
	@NSManaged public var seriesType: String?
	@NSManaged public var originalSize: Int64
	@NSManaged public var resolution: String?
	@NSManaged public var dataPointData: String?
	@NSManaged public var activity: RVActivity?
	@NSManaged public var segment: RVSegment?
	@NSManaged public var effort: RVEffort?
	
}

// MARK: Generated accessors for dataPoints
extension RVStream {
	
	@objc(addDataPointsObject:)
	@NSManaged public func addToDataPoints(_ value: RVStreamData)
	
	@objc(removeDataPointsObject:)
	@NSManaged public func removeFromDataPoints(_ value: RVStreamData)
	
	@objc(addDataPoints:)
	@NSManaged public func addToDataPoints(_ values: NSSet)
	
	@objc(removeDataPoints:)
	@NSManaged public func removeFromDataPoints(_ values: NSSet)
	
}

// Data accessor for 'type'
extension RVStream {
	var type : RVStreamDataType {
		get {
//			appLog.debug("Strava Type is \(self.stravaType)")
			return RVStreamDataType(rawValue: self.stravaType) ?? .unknown
		}
		set {
			self.stravaType = newValue.rawValue
		}
	}
}

