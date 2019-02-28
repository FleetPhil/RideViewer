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
	case shortRide
	case longRide
	case virtualRide
	case walk
	case other
	
	var displayString: String {
		switch self {
		case .cycleRide:		return "Cycle Rides"
		case .virtualRide:		return "Virtual Rides"
		case .longRide:			return "Long Rides"
		case .shortRide:		return "Short Rides"
		case .walk:				return "Walks"
		case .other:			return "Other Activities"
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
		case .longRide:			return NSPredicate(format: "distance >= %f", 	argumentArray: [longRideLimit])
		case .shortRide:		return NSPredicate(format: "distance < %f", 	argumentArray: [longRideLimit])
		case .walk:				return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Walk.rawValue])
		case .other:			return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Workout.rawValue])

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
        
        if let activityMap = activity.map {
            self.map					= RVMap.create(map: activityMap, context: self.managedObjectContext!)
        } else {
            self.map = nil
        }
        
        if self.resourceState != .detailed {            // If current state is detailed we already have segments
            self.resourceState = self.resourceState.newState(returnedState: activity.resourceState)
            
            if let efforts = activity.segmentEfforts {			// Detailed activity
                for effort in efforts {
                    let _ = RVEffort.create(effort: effort, forActivity : self, context: self.managedObjectContext!)
                }
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

// Extension to support generic table view
extension RVActivity : TableViewCompatibleEntity {
    func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> TableViewCompatibleCell {
        return (tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath) as! ActivityListTableViewCell).configure(withModel: self)
    }
}

// Extension to support photos
extension RVActivity {
	// Return photo asset identifiers to completion handler on main thread
	func getPhotoAssets(force : Bool, completionHandler : @escaping ([RVPhotoAsset])->Void) {
		if !force && self.photoScanDate != nil {
			completionHandler(Array(self.photos).sorted(by: { ($0.photoDate as Date) < ($1.photoDate as Date) }))
			return
		}
		
		CoreDataManager.sharedManager().viewContext.automaticallyMergesChangesFromParent = true
		CoreDataManager.sharedManager().persistentContainer.performBackgroundTask( { context in
			let contextSelf = (context.object(with: self.objectID) as! RVActivity)
			_ = context.deleteObjects(contextSelf.photos)
			
			let photos = PhotoManager.shared().photosForTimePeriod(self.startDate as Date, duration: self.elapsedTime)
			guard photos.count <= Settings.sharedInstance.maxPhotosForActivity else {
				appLog.error("More than \(Settings.sharedInstance.maxPhotosForActivity) photos for \(self.name) on \(self.startDate)")
				return
			}
			photos.forEach({ asset in
				let newAsset = RVPhotoAsset.create(asset: asset, context: context)
				newAsset.activity = context.object(with: self.objectID) as? RVActivity
			})
			contextSelf.photoScanDate = Date() as NSDate
			context.saveContext()
			DispatchQueue.main.async() {
				completionHandler(Array(self.photos).sorted(by: { ($0.photoDate as Date) < ($1.photoDate as Date) }))
			}
		})
	}
}

protocol PhotoOwningObject {
	var photos: Set<RVPhotoAsset> { get set }
	
}

extension RVActivity : PhotoOwningObject {
	
}





// Table cell
class ActivityListTableViewCell : UITableViewCell, TableViewCompatibleCell {
    
    @IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var photoIcon: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func configure(withModel: TableViewCompatibleEntity) -> TableViewCompatibleCell {
        if let activity = withModel as? RVActivity {
			
            let effortCount = activity.efforts.count
            
            nameLabel.text		= "\(effortCount) " + activity.type.emoji + " " + activity.name + (activity.streams.count > 0 ? " 🔹" : "")
            nameLabel.textColor	= activity.resourceState.resourceStateColour
			
			photoIcon.text		= activity.photos.count > 0 ? "\u{1F4F7}" : ""
            
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




