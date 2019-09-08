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
import Accelerate

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
        return [RVStreamDataType.speed, .heartRate, .power, .cadence, .gearRatio, .cumulativePower, .cumulativeHR, .time]
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
			func speedFormatter(value : Speed)->String { return value.speedDisplayString }
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
//            func gearFormatter(value : Double)->String { return (rearTeeth(gearRatio: value) ?? 0).fixedFraction(digits: 0) }
            func gearFormatter(value : Double)->String { return "\((rearTeeth(gearRatio: value) ?? 0))" }
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
    private func rearTeeth(gearRatio : Double) -> Int? {
        if gearRatio == 0 { return nil }
        let x = (Double(BikeConstants.InnerChainRing)*(Double(BikeConstants.Circumference)/1000.0))/(gearRatio*60.0)
        return Int(round(x))
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
	private func update(seriesType: String?, originalSize: Int, data: [Double]) -> RVStream {
		self.seriesType		= seriesType
		self.originalSize	= Int64(originalSize)
		
		// Replace data points
		dataPoints = data
		return self
	}
    
//    // Helper methods
//    func isType(_ type : RVStreamDataType) -> Bool {
//        return self.type == type
//    }
    
    /**
     Return the set of data points for this stream using the x axis stream in the parameter, scaled to unit increments on the x axis
     
     - Parameter axisStream: the x axis values corresponding to this stream (i.e distance or time)
    
     - Returns: the set of (x, y) data points for this stream
     
    */
    func dataPointsWithAxis(_ axisStream : RVStream ) -> [DataPoint] {
        // Only unpack the axis stream data points from JSON once (for performance reasons)
        let axisDataPoints = axisStream.dataPoints.map({ $0 / DisplayConstants.ProfileDistanceIncrement })           // Set data increment in metres. TODO: adjust for time
        guard axisDataPoints.count > 0 else {
            appLog.debug("No data points")
            return []
        }

        // Rebase the x axis to start at zero
        let axisStartValue = axisDataPoints.first!
        let transformedAxisStream = axisDataPoints.map({ $0 - axisStartValue })
        
        appLog.verbose("\(self.dataPoints.count) data points in stream type \(self.type), last axis value is \(Int(transformedAxisStream.last!)) ")

        // Scale to unit increments on the x axis
        let strideIn = vDSP_Stride(1)
        let strideOut = vDSP_Stride(1)
        var newValues = [Double](repeating: 0, count: Int(round(transformedAxisStream.last!)))
        vDSP_vgenpD(self.dataPoints, strideIn, transformedAxisStream, strideIn, &newValues, strideOut, vDSP_Length(newValues.count), vDSP_Length(self.dataPoints.count))

        appLog.verbose("\(newValues.count) new data points from \(newValues.first!) to \(newValues.last!)")
        
        let startTime = Date()
        // Convert to array of DataPoint
        let dataPoints = newValues
            .filter({ (self.type == .power || self.type == .cadence) ? true : $0 != 0 })
            .enumerated()
            .map({ DataPoint(dataValue: $0.element, axisValue: Double($0.offset) * DisplayConstants.ProfileDistanceIncrement) })

        if dataPoints.count == 0 {
            appLog.error("No data points for \(self.type)")
        } else {
            appLog.debug("Returning \(dataPoints.count) points, axis range to \(dataPoints.last!.axisValue) in \(Date().timeIntervalSince(startTime).fixedFraction(digits: 3))")
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
