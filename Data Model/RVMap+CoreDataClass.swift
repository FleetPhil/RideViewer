//
//  RVMap+CoreDataClass.swift
//  RideViewer
//
//  Created by Phil Diggens on 31/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData
import CoreLocation
import Polyline
import StravaSwift

@objc(RVMap)
public class RVMap: NSManagedObject {

	// Class Methods
	class func create(map: Map, context: NSManagedObjectContext) -> RVMap {
		guard map.id != nil else {
			appLog.error("No ID for new Map object")
			return RVMap(context: context)
		}
		let newMap = RVMap.get(identifier: map.id!, inContext: context) ?? RVMap(context: context)
		newMap.id				= map.id!
		newMap.polyline 		= map.polyline ?? ""
		newMap.summaryPolyline	= map.summaryPolyline
        newMap.resourceState    = .undefined
        
        newMap.resourceState = newMap.resourceState.newState(returnedState: map.resourceState)

		return newMap
	}
	
	class func get(identifier: String, inContext context: NSManagedObjectContext) -> RVMap? {
		// Get the map with the specified identifier
		if let map : RVMap = context.fetchObject(withKeyValue: identifier, forKey: "id") {
			return map
		} else {			// Not found
			return nil
		}
	}
	
	func polylineLocations(summary : Bool = false) -> [CLLocationCoordinate2D]? {
		// If oly one is valid return it
		if self.polyline.isValid() && !self.summaryPolyline.isValid() { return decodePolyline(self.polyline!) }
		if !self.polyline.isValid() && self.summaryPolyline.isValid() { return decodePolyline(self.summaryPolyline!) }

		// Both invalid - return nil
		if !self.polyline.isValid() && !self.summaryPolyline.isValid() { return nil }

		// Both valid - return preference
		return summary ? decodePolyline(self.summaryPolyline!) : decodePolyline(self.polyline!)
	}
}

extension Optional where Wrapped == String {
	func isValid() -> Bool {
		switch self {
		case .none: return false
		case .some(let value):	return value == "" ? false : true
		}
	}
}
