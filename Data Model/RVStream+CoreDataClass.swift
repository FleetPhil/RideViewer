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
	class func createForActivity(_ activity: RVActivity, stream: StravaSwift.Stream, context: NSManagedObjectContext) -> RVStream {
		if let dataStream = activity.streams.filter({ $0.type! == stream.type!.rawValue }).first {		// Exists
			return dataStream.update(stream: stream)
		}
		let newStream = RVStream(context: context)
		newStream.activity = activity
		return newStream.update(stream: stream)
	}

	class func createForSegment(_ segment: RVSegment, stream: StravaSwift.Stream, context: NSManagedObjectContext) -> RVStream {
		if let dataStream = segment.streams.filter({ $0.type! == stream.type!.rawValue }).first {		// Exists
			return dataStream.update(stream: stream)
		}
		let newStream = RVStream(context: context)
		newStream.segment = segment
		appLog.debug("Stream \(stream.type!) created for \(segment.name!)")
		return newStream.update(stream: stream)
	}

	class func createForEffort(_ effort: RVEffort, stream: StravaSwift.Stream, context: NSManagedObjectContext) -> RVStream {
		if let dataStream = effort.streams.filter({ $0.type! == stream.type!.rawValue }).first {		// Exists
			return dataStream.update(stream: stream)
		}
		let newStream = RVStream(context: context)
		newStream.effort = effort
		return newStream.update(stream: stream)
	}

	func update(stream : StravaSwift.Stream) -> RVStream {
		self.type			= stream.type!.rawValue
		self.seriesType		= stream.seriesType!
		self.originalSize	= Int64(stream.originalSize ?? 0)

		guard let data = stream.data else { return self }
		
		// Replace data points
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
	
	private var dataPointData : String = ""
	
	var dataPoints2 : [Double]? {
		get {
			if let jsonData = dataPointData.data(using: .utf8) {
				let dataPoints = try? JSONDecoder().decode([Double].self, from: jsonData)
				return dataPoints
			}
			return []
		}
		set {
			if newValue != nil {
				if let jsonData = try? JSONEncoder().encode(newValue!) {
					dataPointData = String(data: jsonData, encoding: .utf8)!
				} else {
					dataPointData = ""
				}
			} else {
				dataPointData = ""
			}
		}
	}
}
