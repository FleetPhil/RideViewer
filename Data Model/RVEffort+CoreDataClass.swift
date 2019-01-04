//
//  RVEffort+CoreDataClass.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit
import StravaSwift

@objc(RVEffort)
public class RVEffort: NSManagedObject {
	// Class Methods
	class func create(effort: Effort, forActivity : RVActivity, context: NSManagedObjectContext) -> RVEffort {
		return (RVEffort.get(identifier: effort.id!, inContext: context) ?? RVEffort(context: context)).update(effort: effort, activity : forActivity)
	}
	
	class func get(identifier: Int, inContext context: NSManagedObjectContext) -> RVEffort? {
		// Get the effort with the specified identifier
		if let effort = context.fetchObjectForEntityName(RVEffort.entityName, withKeyValue: identifier, forKey: "id") as! RVEffort? {
			return effort
		} else {			// Not found
			return nil
		}
	}
	
	func update(effort : Effort, activity :  RVActivity) -> RVEffort {
		self.id						= Int64(effort.id!)
		self.name					= effort.name ?? "No name"
		self.distance				= effort.distance!
		self.movingTime				= Double(effort.movingTime!)
		self.elapsedTime			= Double(effort.elapsedTime!)
		self.startDate				= effort.startDate! as NSDate
		self.averageCadence			= effort.averageCadence ?? 0.0
		self.averageWatts			= effort.averageWatts ?? 0.0
		self.averageHeartRate		= effort.averageHeartRate ?? 0.0
		self.maxHeartRate			= Double(effort.maxHeartRate ?? 0)
		self.komRank				= Int16(effort.komRank ?? 0)
		self.prRank					= Int16(effort.prRank ?? 0)
		
		let resourceStateValue 		= Int16(effort.resourceState != nil ? effort.resourceState!.rawValue : 0)
		self.resourceState			= ResourceState(rawValue: resourceStateValue) ?? .undefined

		self.activity				= activity
        
        // Get or create the related segment
        if let segmentID = effort.segment?.id {
            if let rvSegment = RVSegment.get(identifier: segmentID, inContext: self.managedObjectContext!) {
                self.segment = rvSegment
            } else {            // Segment does not exist
                let newSegment = RVSegment.create(segment: effort.segment!, context: self.managedObjectContext!)
                self.segment = newSegment
            }
        }
		
//        if let effortSegment = effort.segment {
//            if let segmentID = effortSegment.id {
//                if let rvSegment = RVSegment.get(identifier: segmentID, inContext: self.managedObjectContext!) {
//                    self.segment = rvSegment
//                    appLog.debug("Got seg '\(effortSegment.name ?? "?")' for act '\(activity.name)', state \(rvSegment.resourceState.rawValue)")
//                    // Check the resource state and request details if not there already
//                    switch rvSegment.resourceState {
//                    case .detailed:
//                        break
//                    default:
//                        appLog.debug("Updating seg \(rvSegment.name ?? "")")
//                        StravaManager.sharedInstance.updateSegment(rvSegment, context: self.managedObjectContext!) {
//                            appLog.debug("Seg \(rvSegment.name ?? "") details updated")
//                        break
//                    }
//                } else {            // Segment does not exist
//                    appLog.debug("Create seg '\(effortSegment.name ?? "?")' for act \(activity.name)")
//                    let newSegment = RVSegment.create(segment: effortSegment, context: self.managedObjectContext!)
//                    self.segment = newSegment
//                    StravaManager.sharedInstance.updateSegment(newSegment, context: self.managedObjectContext!) {
//                        appLog.debug("New seg \(newSegment.name ?? "") details updated")
//                    }
//                }
//            }
//        }

        return self
	}
}

// Extension to support generic table view
extension RVEffort : TableViewCompatible {
	var reuseIdentifier: String {
		return "EffortCell"
	}
	
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
		if let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as? EffortListTableViewCell {
			cell.configure(withModel: self)
			return cell
		} else {
			appLog.error("Unable to dequeue cell")
			return UITableViewCell()
		}
	}
}

// Table cell
class EffortListTableViewCell : UITableViewCell {
	
	@IBOutlet weak var segmentName: UILabel!
	@IBOutlet weak var distance: UILabel!
	@IBOutlet weak var time: UILabel!
    @IBOutlet weak var powerLabel: UILabel!
    
	func configure(withModel: NSManagedObject) {
		if let effort = withModel as? RVEffort {
			segmentName.text	= effort.segment.name ?? ""
			distance.text		= effort.distance.distanceDisplayString
			time.text			= effort.elapsedTime.shortDurationDisplayString
			powerLabel.text		= "\(Int(round(effort.averageWatts)))"+"W"
            
            powerLabel.textColor = effort.activity.deviceWatts ? UIColor.black : UIColor.darkGray
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
	}
}

