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
		
		let resourceStateValue 		= Int16(map.resourceState != nil ? map.resourceState!.rawValue : 0)
		newMap.resourceState		= ResourceState(rawValue: resourceStateValue) ?? .undefined

		return newMap
	}
	
	class func get(identifier: String, inContext context: NSManagedObjectContext) -> RVMap? {
		// Get the map with the specified identifier
		if let map = context.fetchObjectForEntityName(RVMap.entityName, withKeyValue: identifier, forKey: "id") as! RVMap? {
			return map
		} else {			// Not found
			return nil
		}
	}
	
	func polylineLocations(summary : Bool = false) -> [CLLocationCoordinate2D]? {
		guard let polyline = (summary ? self.summaryPolyline : self.polyline) else { return nil }
		return decodePolyline(polyline)
	}
}
