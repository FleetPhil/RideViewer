//
//  Settings.swift
//  RideViewer
//
//  Created by Home on 02/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import XCGLogger
import StravaSwift

class Settings {
	static let sharedInstance = Settings()
	
	var includeVirtual : Bool 	= false			// Include virtual rides
	var onlyBike : Bool			= true			// Only show cycling activities
	var onlyMeter : Bool		= true			// Only show power from a meter
	
	var activityMinDistance : Double = 10000.0		// minimum distance for activities
	var segmentMinDistance : Double	 = 1000.0		// minimum distance for segments
	
	var maxPhotosForActivity : Int = 50

	deinit {
		appLog.debug("Save settings")
	}
	
//	var activitySettingsPredicate : NSCompoundPredicate {
//		var virtualPredicate : NSPredicate 	= NSPredicate(value: true)
////		var bikePredicate : NSPredicate 	= NSPredicate(value: true)
//		var distancePredicate : NSPredicate	= NSPredicate(value: true)
//
//		if self.includeVirtual == false {		// Filter out virtual rides
//			virtualPredicate = NSPredicate(format: "activityType != %@", ActivityType.virtualRide.rawValue)
//		}
////		if self.onlyBike == true {		// Filter out non-bike activities
////			virtualPredicate = NSPredicate(format: "activity == %@", NSNumber(value: false))
////		}
//		distancePredicate = NSPredicate(format: "distance > %f", self.activityMinDistance)
//
//		return NSCompoundPredicate(andPredicateWithSubpredicates: [virtualPredicate, distancePredicate])
//	}
	
	// Return a segment filter from the settings
	var segmentSettingsPredicate : NSCompoundPredicate {
		var distancePredicate : NSPredicate	= NSPredicate(value: true)
		
		if self.segmentMinDistance > 0 {
			distancePredicate = NSPredicate(format: "distance > %f", self.segmentMinDistance)
		}
		
		return NSCompoundPredicate(andPredicateWithSubpredicates: [distancePredicate])
	}

}
