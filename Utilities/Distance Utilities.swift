//
//  Distance Utilities.swift
//  FlightLog2
//
//  Created by Phil Diggens on 29/04/2017.
//  Copyright © 2017 Phil Diggens. All rights reserved.
//

import Foundation
import MapKit

// Default units
let unitLength : UnitLength = .kilometers
let unitSpeed : UnitSpeed = .kilometersPerHour
let unitDuration : UnitDuration = .hours
let unitHeight : UnitLength = .meters

public typealias Distance = Double
public typealias Duration = Double
public typealias Height = Double
public typealias Speed = Double

// Return distance as a Measurement
extension Distance {
	var distanceMeasurement : Measurement<UnitLength> {
		return Measurement(value: self, unit: UnitLength.meters)
	}
	var distanceDisplayString : String {
		return self.distanceMeasurement.displayFormatter(fractionDigits: 2).string(from: self.distanceMeasurement.converted(to: unitLength))
	}
}

extension Height {
	var heightMeasurement : Measurement<UnitLength> {
		return Measurement(value: self, unit: UnitLength.meters)
	}
	var heightDisplayString : String {
		return self.heightMeasurement.displayFormatter(fractionDigits: 0).string(from: self.heightMeasurement.converted(to: unitHeight))
	}
}

// Return duration as a Measurement
extension Duration {
	var durationMeasurement : Measurement<UnitDuration> {
		return Measurement(value: self, unit: UnitDuration.seconds)
	}
	var durationDisplayString : String {
		let seconds = (self.durationMeasurement).converted(to: UnitDuration.seconds).value
		let hours = Int(seconds / 3600)
		return NSString(format: "%01u:%02u", hours, Int(seconds/60)-(hours*60)) as String
	}
	var shortDurationDisplayString : String {
		let seconds = (self.durationMeasurement).converted(to: UnitDuration.seconds).value
		let minutes = Int(seconds / 60)
		return NSString(format: "%01u:%02u", minutes, Int(seconds)-Int(minutes*60)) as String
	}

}

extension Speed {
	var speedMeasurement : Measurement<UnitSpeed> {
		return Measurement(value: self, unit: UnitSpeed.metersPerSecond)
	}
	var speedDisplayString : String {
		return self.speedMeasurement.displayFormatter(fractionDigits: 1).string(from: self.speedMeasurement.converted(to: unitSpeed))
	}
}

// Convert distance & time to speed
func / (lhs: Measurement<UnitLength>, rhs: Measurement<UnitDuration>) -> Measurement<UnitSpeed> {
	let quantity = lhs.converted(to: unitLength).value / rhs.converted(to: unitDuration).value
	return Measurement(value: quantity, unit: unitSpeed)
}

// Standard formatting
extension Measurement  {
	func displayFormatter(fractionDigits : Int = 0)  -> MeasurementFormatter {
		let measurementFormatter = MeasurementFormatter()
		measurementFormatter.unitOptions = .providedUnit
		measurementFormatter.unitStyle = .medium
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = NumberFormatter.Style.decimal
		numberFormatter.maximumFractionDigits = fractionDigits
		measurementFormatter.numberFormatter = numberFormatter
		return measurementFormatter
	}
}

extension CLLocation {
	func isCloseTo(otherLocation : CLLocation?, tolerance: Distance) -> Bool {
		if otherLocation == nil {
			return false
		} else {
			return self.distance(from: otherLocation!) < tolerance
		}
	}
}


