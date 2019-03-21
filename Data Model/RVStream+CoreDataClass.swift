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
	class func createForOwner<S>(_ owner : S, stream: StravaSwift.Stream, context: NSManagedObjectContext) -> RVStream where S : StreamOwner {
		if owner.streams.count > 0, let dataStream = owner.streams.filter({ $0.type == stream.type!.rawValue }).first {		// Exists
			return dataStream.update(stream: stream)
		}
		let newStream = RVStream(context: context)
		owner.setAsOwnerForStream(newStream)
		return newStream.update(stream: stream)
	}

	// Instance methods
	func update(stream : StravaSwift.Stream) -> RVStream {
		self.type			= stream.type!.rawValue
		self.seriesType		= stream.seriesType!
		self.originalSize	= Int64(stream.originalSize ?? 0)
		
		guard let data = stream.data else { return self }
		
		// Replace data points
		dataPoints = data as? [Double] ?? []
		return self
	}

	var dataPoints : [Double] {
		get {
			guard let data = dataPointData else { return [] }
			if let jsonData = data.data(using: .utf8) {
				let dataPoints = try? JSONDecoder().decode([Double].self, from: jsonData)
				return dataPoints ?? []
			} else {
				return []
			}
		}
		set {
			if let jsonData = try? JSONEncoder().encode(newValue) {
				dataPointData = String(data: jsonData, encoding: .utf8)!
			} else {
				dataPointData = nil
			}
		}
	}
}
