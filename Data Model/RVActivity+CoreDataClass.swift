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
    func detailedActivity(completionHandler : (@escaping (RVActivity?)->Void )) {
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

// Extension to provide extremes for filter
extension RVActivity {
    static func filterLimits(context : NSManagedObjectContext) -> FilterValues? {
        var limits = FilterValues(dateParams: [:], rangeParams: [:])
        
        if let activities : [RVActivity] = context.fetchObjects() {
            guard activities.count > 0 else { return nil }
            
            limits.dateParams[FilterParamName.from.rawValue] = activities.map({ $0.startDate as Date }).min()
            limits.dateParams[FilterParamName.to.rawValue] = activities.map({ $0.startDate as Date }).max()
            
            limits.rangeParams[FilterParamName.movingTime.rawValue] = RouteIndexRange(from: activities.map({ $0.movingTime }).min()!, to: activities.map({ $0.movingTime }).max()!)
            limits.rangeParams[FilterParamName.totalTime.rawValue] = RouteIndexRange(from: activities.map({ $0.elapsedTime }).min()!, to: activities.map({ $0.elapsedTime }).max()!)
            limits.rangeParams[FilterParamName.distance.rawValue] = RouteIndexRange(from: activities.map({ $0.distance }).min()!, to: activities.map({ $0.distance }).max()!)
            limits.rangeParams[FilterParamName.elevationGain.rawValue] = RouteIndexRange(from: activities.map({ $0.elevationGain }).min()!, to: activities.map({ $0.elevationGain }).max()!)
            limits.rangeParams[FilterParamName.averagePower.rawValue] = RouteIndexRange(from: activities.map({ $0.averagePower }).min()!, to: activities.map({ $0.averagePower }).max()!)
            limits.rangeParams[FilterParamName.totalEnergy.rawValue] = RouteIndexRange(from: activities.map({ $0.kiloJoules }).min()!, to: activities.map({ $0.kiloJoules }).max()!)

            return limits
        }
        return nil
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




