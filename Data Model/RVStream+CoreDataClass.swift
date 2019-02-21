//
//  RVStream+CoreDataClass.swift
//  RideViewer
//
//  Created by Home on 25/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//
//

import Foundation
import CoreData
import StravaSwift

@objc(RVStream)
public class RVStream: NSManagedObject {
	
	// Class Methods
	class func create(stream: StravaSwift.Stream, activity : RVActivity, context: NSManagedObjectContext) -> RVStream {
		if let stream = RVStream.get(activity: activity, type: stream.type!.rawValue, inContext: context) {
			return stream
		}
		let newStream = RVStream(context: context)
		newStream.activity = activity
		return newStream.update(stream: stream)
	}
	
	class func get(activity : RVActivity, type: String, inContext context: NSManagedObjectContext) -> RVStream? {
		// Get the stream with the specified type for this activity
		if let stream = activity.streams.filter({ $0.type! == type }).first {
			return stream
		} else {			// Not found
			return nil
		}
	}
	
	func update(stream : StravaSwift.Stream) -> RVStream {
		self.type			= stream.type!.rawValue
		self.seriesType		= stream.seriesType!
		self.originalSize	= Int64(stream.originalSize ?? 0)

		guard let data = stream.data else { return self }
		
		if self.dataPoints.count > 0 {
			_ = self.managedObjectContext?.deleteObjects(self.dataPoints)
		}
		
		var failCount : Int = 0
		for (index, dataPoint) in data.enumerated() {
			if let value = dataPoint as? Double {
				_ = RVStreamData.create(stream: self, index: index, dataPoint: value, context: self.managedObjectContext!)
			} else {
				failCount += 1
			}
		}
//		appLog.debug("Stream \(self.type!): \(failCount) fails, \(self.dataPoints.count) stored")
		return self
	}
}
