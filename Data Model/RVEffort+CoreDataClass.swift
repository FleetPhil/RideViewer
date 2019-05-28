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
import MapKit

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
	
	static var sortOptionsForActivity : [EffortSort] {
		return EffortSort.allCases
	}
	static var sortOptionsForSegment : [EffortSort] {
		return [.speed, .movingTime, .elapsedTime, .date, .maxHR, .averageWatts]
	}
}

enum EffortFilter : String, PopupSelectable, CaseIterable {
	case short				= "Short"
	case long				= "Long"
	case flat				= "Flat"
	case ascending			= "Ascending"
	case descending			= "Descending"
	case singleEffort		= "Single Effort"
	case multipleEfforts	= "Multiple Effort"
	
	var displayString: String { return self.rawValue }
	
	var filterGroup: String {
		switch self {
		case .short, .long: 					return "Segment Length"
		case .flat, .ascending, .descending:	return "Profile"
		case .multipleEfforts, .singleEffort: 	return "Number of Efforts"
		}
	}
	
	func predicateForFilterOption() -> NSPredicate {
		let longLimit = Settings.sharedInstance.segmentMinDistance
		switch self {
		case .short:			return NSPredicate(format: "distance < %f", argumentArray: [longLimit])
		case .long:				return NSPredicate(format: "distance >= %f", argumentArray: [longLimit])
		case .flat:				return NSPredicate(format: "segment.averageGrade = 0", argumentArray: nil)
		case .ascending:		return NSPredicate(format: "segment.averageGrade > 0", argumentArray: nil)
		case .descending:		return NSPredicate(format: "segment.averageGrade < 0", argumentArray: nil)
		case .multipleEfforts:	return NSPredicate(format: "segment.effortCount > 1", argumentArray: nil)
		case .singleEffort:		return NSPredicate(format: "segment.effortCount = 1", argumentArray: nil)
		}
	}
	
	static func predicateForFilters(_ filters : [EffortFilter]) -> NSCompoundPredicate {
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

@objc(RVEffort)
public class RVEffort: NSManagedObject, RouteViewCompatible {
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
    
    class func filterPredicate(activity : RVActivity, range : RouteIndexRange?) -> NSCompoundPredicate {
        var filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "activity.id == %@", argumentArray: [activity.id])])
        if let routeRange = range {     // Only show efforts in specified index range
            let rangePredicate = NSPredicate(format: "startIndex >= %d && startIndex <= %d", argumentArray: [routeRange.from, routeRange.to])
            filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [filterPredicate, rangePredicate])
        }
        return filterPredicate
    }

	class func filterPredicate(segment : RVSegment, range : RouteIndexRange?) -> NSCompoundPredicate {
		var filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "segment.id == %@", argumentArray: [segment.id])])
		if let routeRange = range {     // Only show efforts in specified index range
			let rangePredicate = NSPredicate(format: "startIndex >= %d && startIndex <= %d", argumentArray: [routeRange.from, routeRange.to])
			filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [filterPredicate, rangePredicate])
		}
		return filterPredicate
	}

	// Route view compatible
	var startLocation: CLLocationCoordinate2D {
		return self.segment.startLocation
	}
	
	var endLocation: CLLocationCoordinate2D {
		return self.segment.endLocation
	}
    var coordinates: [CLLocationCoordinate2D]? {
        return self.segment.map?.polylineLocations(summary: false)
    }
	
	// Get start and end distance in activity for this effort
	var distanceRangeInActivity : RouteIndexRange {
		if let stream = self.activity.streams.filter({ $0.type == .distance }).first {
			let dataPoints = stream.dataPoints
			return RouteIndexRange(from: dataPoints[Int(self.startIndex)], to: dataPoints[Int(self.endIndex)])
		} else {
			return RouteIndexRange(from: 0.0, to: 0.0)
		}
	}
}

// Extension to return of stream data
extension RVEffort {
    /**
     Get streams for this effort
     
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
        StravaManager.sharedInstance.streamsForEffort(self, context: self.managedObjectContext!, completionHandler: { success in
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
// Need to support 3 versions: efforts for activity, efforts for segment and all efforts
// enum raw value is stored in the tag

enum EffortTableViewType : Int {
	case effortsForActivity = 1
	case effortsForSegment = 2
    case allEfforts = 3
}

extension RVEffort : TableViewCompatibleEntity {
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> TableViewCompatibleCell {
		if let tableType = EffortTableViewType(rawValue: tableView.tag) {
			switch tableType {
			case .effortsForActivity, .allEfforts:
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
		effortText.append(NSAttributedString(string: "  ⏩ " + (self.distance / self.elapsedTime).speedDisplayString()))
		if self.activity.hasHeartRate {
			effortText.append(NSAttributedString(string: " " + EmojiConstants.HeartRate + " " + self.maxHeartRate.fixedFraction(digits: 0)))
		}
		
		let powerAttributes : [NSAttributedString.Key : Any] = self.activity.deviceWatts ? [:] : [.foregroundColor : UIColor.lightGray]
		effortText.append(NSAttributedString(string: " " +  EmojiConstants.Power + self.averageWatts.fixedFraction(digits: 0) + "W", attributes: powerAttributes))
		
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
			
			let segmentStarText = effort.segment.starred ? "★" : "☆"
			segmentName.text = segmentStarText + " " + effort.segment.name! + (effort.streams.count > 0 ? " ⇉" : "")
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
			
			activityName.text = effort.activity.name + (effort.streams.count > 0 ? " ⇉" : "")
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
