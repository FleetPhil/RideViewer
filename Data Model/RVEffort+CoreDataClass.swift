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
		self.startIndex				= Int64(effort.startIndex ?? 0)
		self.endIndex				= Int64(effort.endIndex ?? 0)
		
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
// Need to support 2 versions: efforts for activity and efforts for segment
// enum raw value is stored in the tag

enum EffortTableViewType : Int {
	case effortsForActivity = 1
	case effortsForSegment = 2
}

extension RVEffort : TableViewCompatible {
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
		if let tableType = EffortTableViewType(rawValue: tableView.tag) {
			switch tableType {
			case .effortsForActivity:
				return (tableView.dequeueReusableCell(withIdentifier: "ActivityEffortCell", for: indexPath) as! EffortListForActivityTableViewCell).configure(withModel: self)
			case .effortsForSegment:
				return (tableView.dequeueReusableCell(withIdentifier: "SegmentEffortCell", for: indexPath) as! EffortListForSegmentTableViewCell).configure(withModel: self)
			}
		} else {
			appLog.error("Unknown table type \(tableView.tag)")
			return UITableViewCell()
		}
	}
}

// Table cell
class EffortListForActivityTableViewCell : UITableViewCell {
	
	@IBOutlet weak var segmentName: UILabel!
	@IBOutlet weak var segmentData: UILabel!
	@IBOutlet weak var effortData: UILabel!
	
	func configure(withModel: NSManagedObject) -> EffortListForActivityTableViewCell {
		if let effort = withModel as? RVEffort {
			
			segmentName.text = effort.segment.name! + " " + ["","\u{2463}","\u{2462}","\u{2461}","\u{2460}", ""][5 - Int(effort.segment.climbCategory)]
			
			segmentData.text = "➡️ " + effort.distance.distanceDisplayString
				+ "  ↗️ " + (effort.segment.maxElevation - effort.segment.minElevation).heightDisplayString
				+ "  Av \(effort.segment.averageGrade.fixedFraction(digits: 1))%"
				+ "  Max \(effort.segment.maxGrade.fixedFraction(digits: 1))%"
			
			effortData.text = "⏱ " + effort.elapsedTime.shortDurationDisplayString
				+ "  ⏩ " + (effort.distance / effort.elapsedTime).speedDisplayString
				+ "  🔌 \(effort.averageWatts.fixedFraction(digits: 0))W"
				+ "  ❤️ \(effort.maxHeartRate.fixedFraction(digits: 0))"
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
		return self
	}
}

class EffortListForSegmentTableViewCell : UITableViewCell {
	
	@IBOutlet weak var activityName: UILabel!
	@IBOutlet weak var activityDate: UILabel!
	@IBOutlet weak var effortData: UILabel!
	
	func configure(withModel: NSManagedObject) -> EffortListForSegmentTableViewCell {
		if let effort = withModel as? RVEffort {
			
			activityName.text = effort.activity.name
			activityDate.text = (effort.activity.startDate as Date).displayString(displayType: .dateOnly)
			
			let effortText = NSMutableAttributedString(string: "⏱ " + effort.elapsedTime.shortDurationDisplayString)
			effortText.append(NSAttributedString(string: "  ⏩ " + (effort.distance / effort.elapsedTime).speedDisplayString))
			effortText.append(NSAttributedString(string: effort.maxHeartRate > 0 ? "  ❤️ \(effort.maxHeartRate.fixedFraction(digits: 0))" : ""))

			let powerAttributes : [NSAttributedString.Key : Any] = effort.activity.deviceWatts ? [:] : [.foregroundColor : UIColor.lightGray]
			effortText.append(NSAttributedString(string: "  🔌 \(effort.averageWatts.fixedFraction(digits: 0))W", attributes: powerAttributes))
			
			effortData.attributedText = effortText
			
//			effortData.text = "⏱ " + effort.elapsedTime.shortDurationDisplayString
//				+ "  ⏩ " + (effort.distance / effort.elapsedTime).speedDisplayString
//				+ "  🔌 \(effort.averageWatts.fixedFraction(digits: 0))W"
//				+ "  ❤️ \(effort.maxHeartRate.fixedFraction(digits: 0))"
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
		return self
	}
}
