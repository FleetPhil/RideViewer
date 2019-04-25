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
import Charts

// Stream data type
enum RVStreamDataType : String {
	// Strava Values
	case speed 		= "velocity_smooth"
	case altitude
	case heartRate 	= "heartrate"
	case power 		= "watts"
	case distance
	case cadence
	case time
	
	// Calculated values
	case gearRatio
	
	// Error
	case unknown
	
	var stringValue : String {
		return self.rawValue
	}

	var chartValueFormatter : AxisValueFormatter {
		switch self {
		case .speed:
			func speedFormatter(value : Speed)->String { return value.speedDisplayString() }
			return AxisValueFormatter(numberFormatter: speedFormatter)
		case .cadence:
			func zeroFractionFormatter(value : Double)->String { return value.fixedFraction(digits: 0) }
			return AxisValueFormatter(numberFormatter: zeroFractionFormatter)
		case .altitude:
			func altFormatter(value : Double)->String { return value.fixedFraction(digits: 0) + "m" }
			return AxisValueFormatter(numberFormatter: altFormatter)
		case .heartRate:
			func hrFormatter(value : Double)->String { return value.fixedFraction(digits: 0) + "bpm" }
			return AxisValueFormatter(numberFormatter: hrFormatter)
		case .power:
			func powerFormatter(value : Double)->String { return value.fixedFraction(digits: 0) + "W" }
			return AxisValueFormatter(numberFormatter: powerFormatter)
		default:
			func defaultFormatter(value : Double)->String { return value.fixedFraction(digits: 1) }
			return AxisValueFormatter(numberFormatter: defaultFormatter)
		}
	}
}


@objc(RVStream)
public class RVStream: NSManagedObject {
	
	// Class Methods
	// Initializer with StravaSwift data
	@discardableResult
	class func createWithStrava<S>(owner : S, stream: StravaSwift.Stream, context: NSManagedObjectContext) -> RVStream where S : StreamOwner {
		if let dataStream = owner.streams.filter({ $0.stravaType == stream.type?.rawValue }).first {		// Exists
			return dataStream.update(seriesType: stream.seriesType, originalSize: stream.originalSize ?? 0, data: stream.data as? [Double] ?? [])
		}
		let newStream = RVStream(context: context)
		newStream.stravaType = stream.type!.rawValue
		owner.setAsOwnerForStream(newStream)
		return newStream.update(seriesType: stream.seriesType!, originalSize: stream.originalSize ?? 0, data: stream.data as? [Double] ?? [])
	}
	
	// Initializer with non-StravaSwift data
	@discardableResult
	class func createWithData<S>(owner : S, type: RVStreamDataType, seriesType: String, originalSize: Int, data: [Double], context: NSManagedObjectContext) -> RVStream where S : StreamOwner {
		if let dataStream = owner.streams.filter({ $0.stravaType == type.stringValue }).first {		// Exists
			return dataStream.update(seriesType: seriesType, originalSize: originalSize, data: data)
		}
		let newStream = RVStream(context: context)
		newStream.type = type
		owner.setAsOwnerForStream(newStream)
		return newStream.update(seriesType: seriesType, originalSize: originalSize, data: data)
	}

	// Instance methods
	func update(seriesType: String?, originalSize: Int, data: [Double]) -> RVStream {
		self.seriesType		= seriesType
		self.originalSize	= Int64(originalSize)
		
		// Replace data points
		dataPoints = data
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
