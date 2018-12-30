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

@objc(RVActivity)
public class RVActivity: NSManagedObject {
	
	// Computed variables
	var startLocation : CLLocationCoordinate2D	{
		return CLLocationCoordinate2D(latitude: self.startLat, longitude: self.startLong)
	}
	var endLocation : CLLocationCoordinate2D	{
		return CLLocationCoordinate2D(latitude: self.endLat, longitude: self.endLong)
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
		if let activity = context.fetchObjectForEntityName(RVActivity.entityName, withKeyValue: identifier, forKey: "id") as! RVActivity? {
			return activity
		} else {			// Not found
			return nil
		}
	}
	
	func update(activity : Activity) -> RVActivity {
		self.id						= Int64(activity.id!)
		self.name					= activity.name ?? "No name"
		self.activityDescription	= activity.description
		self.distance				= activity.distance!
		self.movingTime				= activity.movingTime!
		self.elapsedTime			= activity.elapsedTime!
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
		
		let resourceStateValue 		= Int16(activity.resourceState != nil ? activity.resourceState!.rawValue : 0)
		self.resourceState			= ResourceState(rawValue: resourceStateValue) ?? .undefined
		
		if let efforts = activity.segmentEfforts {
			for effort in efforts {
				let _ = RVEffort.create(effort: effort, forActivity : self, context: self.managedObjectContext!)
			}
		}
		
		return self
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
extension RVActivity : TableViewCompatible {
	var reuseIdentifier: String {
		return "ActivityCell"
	}
	
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
		if let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as? ActivityListTableViewCell {
			cell.configure(withModel: self)
			return cell
		} else {
			appLog.error("Unable to dequeue cell")
			return UITableViewCell()
		}
	}
}

// Table cell
class ActivityListTableViewCell : UITableViewCell {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	
	func configure(withModel: NSManagedObject) {
		if let activity = withModel as? RVActivity {
			
			appLog.debug("Activity state is \(activity.resourceState.rawValue)")

			nameLabel.text		= activity.name
			dateLabel.text		= (activity.startDate as Date).displayString(displayType: .dateTime)
			distanceLabel.text	= activity.distance.distanceDisplayString
			timeLabel.text		= activity.elapsedTime.durationDisplayString
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
	}
}




