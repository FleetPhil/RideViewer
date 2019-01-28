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

enum EffortSort : String, PopupSelectable, CaseIterable, Equatable {
	case sequence		= "startIndex"
	case distance 		= "distance"
	case speed			= "averageSpeed"
	case movingTime 	= "movingTime"
	case elapsedTime	= "elapsedTime"
	case date			= "startDate"
	case maxHR			= "maxHeartRate"
	case averageWatts 	= "averageWatts"
	
	var displayString : String {           // Text to use when choosing item
		switch self {
		case .sequence:			return "Sequence"
		case .distance:			return "Distance"
		case .speed:			return "Av. Speed"
		case .movingTime:		return "Moving Time"
		case .elapsedTime:		return "Elapsed Time"
		case .date:				return "Date"
		case .maxHR:			return "Max HR"
		case .averageWatts:		return "Av. Power"
		}
	}

    var defaultAscending : Bool {
        switch self {
		case .sequence:			return true
        case .distance:         return false
		case .speed:			return false
        case .movingTime:       return true
		case .elapsedTime:		return true
        case .date:             return false
        case .maxHR:            return false
        case .averageWatts:     return false
        }
    }
}


@objc(RVEffort)
public class RVEffort: NSManagedObject {
	// Class Methods
	class func create(effort: Effort, forActivity : RVActivity, context: NSManagedObjectContext) -> RVEffort {
		return (RVEffort.get(identifier: effort.id!, inContext: context) ?? RVEffort(context: context)).update(effort: effort, activity : forActivity)
	}
	
	class func get(identifier: Int, inContext context: NSManagedObjectContext) -> RVEffort? {
		// Get the effort with the specified identifier
		if let effort : RVEffort = context.fetchObject(withKeyValue: identifier, forKey: "id") {
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
		self.averageSpeed			= effort.distance! / Double(effort.elapsedTime!)		// in m/s
		self.maxHeartRate			= Double(effort.maxHeartRate ?? 0)
		self.komRank				= Int16(effort.komRank ?? 0)
		self.prRank					= Int16(effort.prRank ?? 0)
		self.startIndex				= Int64(effort.startIndex ?? 0)
		self.endIndex				= Int64(effort.endIndex ?? 0)

        self.resourceState = self.resourceState.newState(returnedState: effort.resourceState)

		self.activity				= activity
		
        // Get or create the related segment
        if let segmentID = effort.segment?.id {
            if let rvSegment = RVSegment.get(identifier: segmentID, inContext: self.managedObjectContext!) {
                self.segment = rvSegment
				self.segment.effortCount = Int64(self.segment.efforts.count)
            } else {            // Segment does not exist
                let newSegment = RVSegment.create(segment: effort.segment!, context: self.managedObjectContext!)
                self.segment = newSegment
				self.segment.effortCount = 1
            }
        }
        return self
	}
}

// Extension to support photos
extension RVEffort {
	// Return photo asset identifiers to completion handler on main thread
	func getPhotoAssets(force : Bool, completionHandler : @escaping ([RVPhotoAsset])->Void) {
		if !force && self.photoScanDate != nil {
			completionHandler(Array(self.photos).sorted(by: { ($0.photoDate as Date) < ($1.photoDate as Date) }))
			return
		}
		
		CoreDataManager.sharedManager().viewContext.automaticallyMergesChangesFromParent = true
		CoreDataManager.sharedManager().persistentContainer.performBackgroundTask( { context in
			let contextSelf = (context.object(with: self.objectID) as! RVEffort)
			contextSelf.photos.forEach({ context.delete($0) })
			
			let photos = PhotoManager.shared().photosForTimePeriod(self.startDate as Date, duration: self.elapsedTime)
			guard photos.count <= Settings.sharedInstance.maxPhotosForActivity else {
				appLog.error("More than \(Settings.sharedInstance.maxPhotosForActivity) photos for \(self.name!) on \(self.startDate)")
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



// Extension to support generic table view
// Need to support 2 versions: efforts for activity and efforts for segment
// enum raw value is stored in the tag

enum EffortTableViewType : Int {
	case effortsForActivity = 1
	case effortsForSegment = 2
}

extension RVEffort : TableViewCompatibleEntity {
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> TableViewCompatibleCell {
		if let tableType = EffortTableViewType(rawValue: tableView.tag) {
			switch tableType {
			case .effortsForActivity:
				return (tableView.dequeueReusableCell(withIdentifier: "ActivityEffortCell", for: indexPath) as! EffortListForActivityTableViewCell).configure(withModel: self)
			case .effortsForSegment:
				return (tableView.dequeueReusableCell(withIdentifier: "SegmentEffortCell", for: indexPath) as! EffortListForSegmentTableViewCell).configure(withModel: self)
			}
		} else {
			appLog.error("Unknown table type \(tableView.tag)")
			return UITableViewCell() as! TableViewCompatibleCell
		}
	}
}

extension RVEffort {
	var effortDisplayText : NSAttributedString {
		let effortText = NSMutableAttributedString(string: "⏱ " + self.elapsedTime.shortDurationDisplayString)
		effortText.append(NSAttributedString(string: "  ⏩ " + (self.distance / self.elapsedTime).speedDisplayString))
		effortText.append(NSAttributedString(string: self.maxHeartRate > 0 ? "  ❤️ \(self.maxHeartRate.fixedFraction(digits: 0))" : ""))
		
		let powerAttributes : [NSAttributedString.Key : Any] = self.activity.deviceWatts ? [:] : [.foregroundColor : UIColor.lightGray]
		effortText.append(NSAttributedString(string: "  🔌 \(self.averageWatts.fixedFraction(digits: 0))W", attributes: powerAttributes))
		
		return effortText
	}
}

// Table cell
class EffortListForActivityTableViewCell : UITableViewCell, TableViewCompatibleCell {
	
	@IBOutlet weak var segmentName: UILabel!
	@IBOutlet weak var segmentData: UILabel!
	@IBOutlet weak var effortData: UILabel!
	
	func configure(withModel: TableViewCompatibleEntity) -> TableViewCompatibleCell {
		if let effort = withModel as? RVEffort {
            
			segmentName.text = effort.segment.name! + " " + ["","\u{2463}","\u{2462}","\u{2461}","\u{2460}", ""][5 - Int(effort.segment.climbCategory)]
            segmentName.textColor = effort.segment.resourceState.resourceStateColour
			
			segmentData.text = "➡️ " + effort.distance.distanceDisplayString
				+ "  ↗️ " + (effort.segment.maxElevation - effort.segment.minElevation).heightDisplayString
				+ "  Av \(effort.segment.averageGrade.fixedFraction(digits: 1))%"
				+ "  Max \(effort.segment.maxGrade.fixedFraction(digits: 1))%"
			
			effortData.attributedText = effort.effortDisplayText
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
		return self
	}
}

class EffortListForSegmentTableViewCell : UITableViewCell, TableViewCompatibleCell {
	
	@IBOutlet weak var activityName: UILabel!
	@IBOutlet weak var activityDate: UILabel!
	@IBOutlet weak var effortData: UILabel!
	
	func configure(withModel: TableViewCompatibleEntity) -> TableViewCompatibleCell  {
		if let effort = withModel as? RVEffort {
			
			activityName.text = effort.activity.name + (effort.activity.streams.count > 0 ? " 🔹" : "")
			activityName.textColor = effort.activity.resourceState.resourceStateColour
			activityDate.text = (effort.activity.startDate as Date).displayString(displayType: .dateOnly, timeZone: effort.activity.timeZone.timeZone)

			effortData.attributedText = effort.effortDisplayText
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
        
        return self
	}
}
