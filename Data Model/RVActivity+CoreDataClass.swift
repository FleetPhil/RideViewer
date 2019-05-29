//
//  RVActivity+CoreDataClass.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData
import StravaSwift
import CoreLocation

enum ActivitySort : String, PopupSelectable, CaseIterable {
    case name		    = "name"
    case distance       = "distance"
    case date           = "startDate"
    case elapsedTime    = "elapsedTime"
    case elevationGain  = "elevationGain"
    case kJ             = "kiloJoules"
    case averageSpeed   = "averageSpeed"
    
    var displayString : String {           // Text to use when choosing item
        switch self {
        case .name: 			return "Name"
        case .distance:			return "Distance"
        case .date:				return "Date"
        case .elapsedTime:		return "Elapsed Time"
        case .elevationGain:	return "Elevation Gain"
        case .kJ:				return "Energy"
        case .averageSpeed:		return "Average Speed"
        }
    }
    
    var defaultAscending : Bool {
        switch self {
        case .name:             return true
        case .distance:         return false
        case .date:             return false
        case .elapsedTime:      return false
        case .elevationGain:    return false
        case .kJ:               return false
        case .averageSpeed:     return false
        }
    }
}

enum ActivityFilter : PopupSelectable, CaseIterable {
	case cycleRide
	case virtualRide
	case walk
	case other
    case shortRide
    case longRide

	var displayString: String {
		switch self {
		case .cycleRide:		return "Cycle Rides"
		case .virtualRide:		return "Virtual Rides"
		case .walk:				return "Walks"
		case .other:			return "Other Activities"
        case .longRide:            return "Long Rides"
        case .shortRide:        return "Short Rides"
		}
	}
	
	var filterGroup: String {
		switch self {
		case .cycleRide, .virtualRide, .walk, .other:		return "Activity Type"
		case .longRide, .shortRide:							return "Ride Length"
		}
	}
	
	func predicateForFilterOption() -> NSPredicate {
		let longRideLimit = Settings.sharedInstance.activityMinDistance
		switch self {
		case .cycleRide:		return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Ride.rawValue])
		case .virtualRide:		return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.VirtualRide.rawValue])
		case .walk:				return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Walk.rawValue])
		case .other:			return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Workout.rawValue])
        case .longRide:            return NSPredicate(format: "distance >= %f",     argumentArray: [longRideLimit])
        case .shortRide:        return NSPredicate(format: "distance < %f",     argumentArray: [longRideLimit])
		}
	}
	
	static func predicateForFilters(_ filters : [ActivityFilter]) -> NSCompoundPredicate {
		var predicates : [NSCompoundPredicate] = []
		let filterGroups = Dictionary(grouping: filters, by: { $0.filterGroup })
		for group in filterGroups {
			let subPred = group.value.map({ $0.predicateForFilterOption() })
			let groupPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPred)
			predicates.append(groupPredicate)
		}
		return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
	}
}

@objc(RVActivity)
public class RVActivity: NSManagedObject, RouteViewCompatible {
    
    // Computed variables
    var startLocation : CLLocationCoordinate2D	{
        return CLLocationCoordinate2D(latitude: self.startLat, longitude: self.startLong)
    }
    var endLocation : CLLocationCoordinate2D	{
        return CLLocationCoordinate2D(latitude: self.endLat, longitude: self.endLong)
    }
    var coordinates: [CLLocationCoordinate2D]? {
        return self.map?.polylineLocations(summary: false)
    }
    
    var activityDate : Date {
        return self.startDate as Date
    }
    
    // Class Methods
    class func create(activity : Activity, context: NSManagedObjectContext) -> RVActivity {
        return (RVActivity.get(identifier: activity.id!, inContext: context) ?? RVActivity(context: context)).update(activity: activity)
    }
    
    class func get(identifier: Int, inContext context: NSManagedObjectContext) -> RVActivity? {
        // Get the activity with the specified identifier
		if let activity : RVActivity = context.fetchObject(withKeyValue: identifier, forKey: "id") {
            return activity
        } else {			// Not found
            return nil
        }
    }
    
    func update(activity : Activity) -> RVActivity {
		if activity.type == nil {
			appLog.debug("Activity type is nil")
		}
		
        self.id						= Int64(activity.id!)
        self.name					= activity.name ?? "No name"
        self.activityDescription	= activity.description
        self.activityType			= activity.type?.rawValue ?? "workout"
        self.distance				= activity.distance!
        self.movingTime				= activity.movingTime!
        self.elapsedTime			= activity.elapsedTime!
        self.lowElevation			= activity.lowElevation ?? 0.0
        self.highElevation			= activity.highElevation ?? 0.0
        self.elevationGain			= activity.totalElevationGain ?? 0.0
        self.startDate				= activity.startDate! as NSDate
        self.timeZone				= timeZoneNameFromActivity(activity.timeZone ?? "")
        self.startLat				= activity.startLatLng?.lat ?? 0.0
        self.startLong				= activity.startLatLng?.lng ?? 0.0
        self.endLat					= activity.endLatLng?.lat ?? 0.0
        self.endLong				= activity.endLatLng?.lng ?? 0.0
        self.averageSpeed			= activity.averageSpeed!
        self.maxSpeed				= activity.maxSpeed ?? 0.0
        self.calories				= activity.calories ?? 0.0
        self.achievementCount		= Int16(activity.achievementCount ?? 0)
        self.kudosCount				= Int16(activity.kudosCount ?? 0)
        self.kiloJoules				= activity.kiloJoules ?? 0.0
        self.averagePower			= activity.averagePower ?? 0.0
        self.maxPower				= activity.maxPower ?? 0.0
        self.deviceWatts			= activity.deviceWatts ?? false
        self.trainer				= activity.trainer ?? false
		self.hasHeartRate			= activity.hasHeartRate ?? false
		self.averageHeartRate		= activity.averageHeartRate ?? 0.0
		self.maxHeartRate			= activity.maxHeartRate ?? 0.0
        
        if let activityMap = activity.map {
            self.map					= RVMap.create(map: activityMap, context: self.managedObjectContext!)
        } else {
            self.map = nil
        }
        
        self.resourceState = self.resourceState.newState(returnedState: activity.resourceState)
            
        if let efforts = activity.segmentEfforts {			// Detailed activity has efforts
            for effort in efforts {
                let _ = RVEffort.create(effort: effort, forActivity : self, context: self.managedObjectContext!)
            }
        }
        return self
    }
    
    var type : ActivityType {
        return ActivityType.init(rawValue: self.activityType)!
    }
    
    func timeZoneNameFromActivity(_ tz : String) -> String {
        if let index = tz.lastIndex(of: " ") {
            return String(tz[tz.index(index, offsetBy: 1)...])
        } else {
            return ""
        }
    }
	
}

// Extension to return activity info from the database or Strava
extension RVActivity {
    func detailedActivity(completionHandler : (@escaping (_ activity : RVActivity?)->Void )) {
        if self.resourceState == .detailed {
            completionHandler(self)
            return
        }
        StravaManager.sharedInstance.getDetailedActivity(self, context: self.managedObjectContext!, completionHandler: { [weak self] success in
            if success {
                self?.managedObjectContext?.saveContext()
                completionHandler(self)
            } else {
                completionHandler(nil)
            }
        })
    }
}

// Extension to return stream data
extension RVActivity {
    /**
     Get streams for this activity
     
     Calls completion handler with nil data not available
     
     - Parameters:
     - completionHandler: function called with the returned streams
     - Returns: none
     */
    func streams(completionHandler : (@escaping (Set<RVStream>?)->Void)) {
        if self.streams.count > 0 {                // We have streams so no need to get from Strava
            completionHandler(self.streams)
            return
        }
        StravaManager.sharedInstance.streamsForActivity(self, context: self.managedObjectContext!, completionHandler: { success in
            if (success) {
                self.managedObjectContext?.saveContext()
                completionHandler(self.streams)
            } else {
                completionHandler(nil)
            }
        })
    }
}


// Extension to support generic table view
extension RVActivity : TableViewCompatibleEntity {
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> TableViewCompatibleCell {
        return (tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath) as! ActivityListTableViewCell).configure(withModel: self)
    }
}



// Table cell
class ActivityListTableViewCell : UITableViewCell, TableViewCompatibleCell {
    
    @IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var featuresLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func configure(withModel: TableViewCompatibleEntity) -> TableViewCompatibleCell {
        if let activity = withModel as? RVActivity {
			
            nameLabel.text		= activity.name
            nameLabel.textColor	= activity.resourceState.resourceStateColour
			
			var features = activity.type.emoji
			if activity.deviceWatts { features += EmojiConstants.Power }
			if activity.hasHeartRate { features += EmojiConstants.HeartRate }
			featuresLabel.text = features
			
			dateLabel.text		= (activity.startDate as Date).displayString(displayType: .dateTime, timeZone: activity.timeZone.timeZone)
            distanceLabel.text	= activity.distance.distanceDisplayString
            timeLabel.text		= activity.elapsedTime.durationDisplayString
            
            self.separatorInset = .zero
        } else {
            appLog.error("Unexpected entity for table view cell")
        }
        
        return self
    }
}




