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
	// Text are Strava Values
    
    // Effort - native
	case speed 		= "velocity_smooth"
	case heartRate 	= "heartrate"
	case power 		= "watts"
	case cadence
    // Effort - calculated
    case gearRatio
    case cumulativePower
    case cumulativeHR

    // X Axis
	case time
    case distance

    // Activity and Segment
    case altitude
	
	// Error
	case unknown
	
	var stringValue : String {
		return self.rawValue
	}
    
    var shortValue : String {
        switch self {
        case .altitude:         return "Alt"
        case .cadence:          return "Cad"
        case .distance:         return "Dist"
        case .gearRatio:        return "GR"
        case .heartRate:        return "HR"
        case .power:            return "Pwr"
        case .speed:            return "Spd"
        case .time:             return "Time"
        case .cumulativePower:  return "∑Pwr"
        case .cumulativeHR:     return "∑HR"
        case .unknown:          return "Unk"
        }
    }
    
    static var effortStreamTypes : [RVStreamDataType] {
        return [RVStreamDataType.speed, .heartRate, .power, .cadence, .gearRatio, .cumulativePower, .cumulativeHR]
    }
    
    func isValidStreamForObjectType(type : StreamOwner) -> Bool {
        switch type {
        case is RVActivity, is RVSegment:
            if self == .altitude { return true } else {return false }
            
        case is RVEffort:
            if RVStreamDataType.effortStreamTypes.contains(self) { return true } else { return false }
        
        default:            // Unknown owner type
            return false
        }
    }

	var chartValueFormatter : AxisValueFormatter {
		switch self {
		case .speed:
			func speedFormatter(value : Speed)->String { return value.speedDisplayString() }
			return AxisValueFormatter(numberFormatter: speedFormatter)
		case .cadence, .cumulativeHR:
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
        case .gearRatio:
            func gearFormatter(value : Double)->String { return (rearTeeth(gearRatio: value) ?? 0).fixedFraction(digits: 0) }
            return AxisValueFormatter(numberFormatter: gearFormatter)
        case .cumulativePower:
            func energyFormatter(value : Double)->String { return (value / 1000).fixedFraction(digits: 0) + "kJ" }
            return AxisValueFormatter(numberFormatter: energyFormatter)
		default:
			func defaultFormatter(value : Double)->String { return value.fixedFraction(digits: 1) }
			return AxisValueFormatter(numberFormatter: defaultFormatter)
		}
	}
    
    /// Return the implied number of rear teeth based on the small chainring and the speed/cadence parameter
    private func rearTeeth(gearRatio : Double) -> Double? {
        if gearRatio == 0 { return nil }
        let x = (Double(BikeConstants.InnerChainRing)*(Double(BikeConstants.Circumference)/1000.0))/(gearRatio*60.0)
        return x
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
    
    /**
     Return the set of y data points for this stream using the x axis stream in the parameter
     
     - Parameter axisStream: the x axis values corresponding to this stream (i.e distance or time)
    
     - Returns: the set of (x, y) data points for this stream
     
    */
    func dataPointsWithAxis(_ axisStream : RVStream ) -> [DataPoint] {
        appLog.verbose("axis: \(axisStream.dataPoints.first!) to \(axisStream.dataPoints.last!)")
        
        // Only unpack the axis stream data points from JSON once (for performance reasons)
        let axisDataPoints = axisStream.dataPoints
        guard axisDataPoints.count > 0 else {
            appLog.debug("No data points found")
            return []
        }
        
        let minAxisValue = axisStream.dataPoints[0]
        let dataPoints = self.dataPoints
            .enumerated()
            .map({ DataPoint(dataValue: $0.element, axisValue: axisDataPoints[$0.offset] - minAxisValue) })
            .filter({
                if (self.type == .power || self.type == .cadence) {         // Zero is valid value for Power and Cadence
                    return true
                } else {
                    return $0.dataValue != 0                                // But filter out other zero values
                }
            })
        
        if dataPoints.count == 0 {
            appLog.error("No data points for \(self.type)")
        } else {
            appLog.verbose("Returning \(dataPoints.count) points, axis range \(dataPoints.first!.axisValue) to \(dataPoints.last!.axisValue), (\(dataPoints.last!.axisValue - dataPoints.first!.axisValue))")
        }
        
        return dataPoints
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
