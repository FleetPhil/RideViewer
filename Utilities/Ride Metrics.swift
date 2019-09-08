//
//  Ride Metrics.swift
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

// Typealias
public typealias Distance = Double
public typealias Duration = Double
public typealias Height = Double
public typealias Speed = Double

// MARK: Measurement

// Return distance as a Measurement
extension Distance {
	var distanceMeasurement : Measurement<UnitLength> {
		return Measurement(value: self, unit: UnitLength.meters)
	}
}

extension Height {
	var heightMeasurement : Measurement<UnitLength> {
		return Measurement(value: self, unit: UnitLength.meters)
	}
}

// Return duration as a Measurement
extension Duration {
	var durationMeasurement : Measurement<UnitDuration> {
		return Measurement(value: self, unit: UnitDuration.seconds)
	}
}

extension Speed {
	var speedMeasurement : Measurement<UnitSpeed> {
		return Measurement(value: self, unit: UnitSpeed.metersPerSecond)
	}
}

// Convert distance & time to speed
func / (lhs: Measurement<UnitLength>, rhs: Measurement<UnitDuration>) -> Measurement<UnitSpeed> {
	let quantity = lhs.converted(to: unitLength).value / rhs.converted(to: unitDuration).value
	return Measurement(value: quantity, unit: unitSpeed)
}

// MARK: Formatting

// Standard formatting
extension Measurement  {
	func displayFormatter(unitStyle : MeasurementFormatter.UnitStyle = .medium,  fractionDigits : Int = 0)  -> MeasurementFormatter {
		let measurementFormatter = MeasurementFormatter()
		measurementFormatter.unitOptions = .providedUnit
		measurementFormatter.unitStyle = unitStyle
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = NumberFormatter.Style.decimal
		numberFormatter.maximumFractionDigits = fractionDigits
		measurementFormatter.numberFormatter = numberFormatter
		return measurementFormatter
	}
}

// Conversion to display strings
extension Double {
    var distanceDisplayString : String {
        return self.distanceMeasurement.displayFormatter(fractionDigits: 2).string(from: self.distanceMeasurement.converted(to: unitLength))
    }
    var heightDisplayString : String {
        return self.heightMeasurement.displayFormatter(fractionDigits: 0).string(from: self.heightMeasurement.converted(to: unitHeight))
    }
    var speedDisplayString : String {
        return self.speedMeasurement.displayFormatter(fractionDigits: 1).string(from: self.speedMeasurement.converted(to: unitSpeed))
    }
    var durationDisplayString : String {
        let minutes = Int(self.durationMeasurement.converted(to: UnitDuration.seconds).value / 60)
        let hours = minutes / 60
        return NSString(format: "%01u:%02u", hours, minutes - hours*60) as String
    }
    var shortDurationDisplayString : String {
        let seconds = Int(self.durationMeasurement.converted(to: UnitDuration.seconds).value)
        var minutes = seconds / 60
        if minutes > 60 {
            let hours = minutes / 60
            minutes -= hours * 60
            return NSString(format: "%u:%02u:%02u", hours, minutes, seconds - (hours * 3600) - (minutes * 60)) as String
        } else {
            return NSString(format: "%01u:%02u", minutes, Int(seconds)-(minutes*60)) as String
        }
    }
    var powerDisplayString : String {
        return self.fixedFraction(digits: 0) + "W"
    }
    
    var energyDisplayString : String {
        return self.fixedFraction(digits: 0) + "kJ"
    }
    
    
    
    
}




