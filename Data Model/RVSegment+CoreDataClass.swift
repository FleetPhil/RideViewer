//
//  RVSegment+CoreDataClass.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//
//

import Foundation
import CoreData
import StravaSwift
import CoreLocation

enum SegmentSort : String, PopupSelectable, CaseIterable {
	case name 		= "name"
	case distance 	= "distance"
	case grade 		= "averageGrade"
	case effortCount = "effortCount"
	
	var displayString : String {           // Text to use when choosing item
		switch self {
		case .name:			return "Name"
		case .distance:		return "Distance"
		case .grade:		return "Av. Grade"
		case .effortCount:	return "Rides"
		}
	}
    
    var defaultAscending : Bool {           //
        switch self {
        case .name:            return true
        case .distance:        return false
        case .grade:           return false
		case .effortCount:	   return false
        }
    }

}

enum SegmentFilter : String, PopupSelectable, CaseIterable {
    case starred            = "Starred"
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
        case .starred:                          return "Starred"
		case .short, .long: 					return "Segment Length"
		case .flat, .ascending, .descending:	return "Profile"
		case .multipleEfforts, .singleEffort: 	return "Number of Efforts"
		}
	}
	
	func predicateForFilterOption() -> NSPredicate {
		let longLimit = Settings.sharedInstance.segmentMinDistance
		switch self {
        case .starred:          return NSPredicate(format: "starred == %@", NSNumber(value: true))
		case .short:			return NSPredicate(format: "distance < %f", argumentArray: [longLimit])
		case .long:				return NSPredicate(format: "distance >= %f", argumentArray: [longLimit])
		case .flat:				return NSPredicate(format: "averageGrade = 0", argumentArray: nil)
		case .ascending:		return NSPredicate(format: "averageGrade > 0", argumentArray: nil)
		case .descending:		return NSPredicate(format: "averageGrade < 0", argumentArray: nil)
		case .multipleEfforts:	return NSPredicate(format: "effortCount > 1", argumentArray: nil)
		case .singleEffort:		return NSPredicate(format: "effortCount = 1", argumentArray: nil)
		}
	}
	
	static func predicateForFilters(_ filters : [SegmentFilter]) -> NSCompoundPredicate {
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


@objc(RVSegment)
public class RVSegment: NSManagedObject, RouteViewCompatible {
	
	// MARK: Computed variables for RouteViewCompatible
	var startLocation : CLLocationCoordinate2D	{
		return CLLocationCoordinate2D(latitude: self.startLat, longitude: self.startLong)
	}
	var endLocation : CLLocationCoordinate2D	{
		return CLLocationCoordinate2D(latitude: self.endLat, longitude: self.endLong)
	}
    var coordinates: [CLLocationCoordinate2D]? {
        return self.map?.polylineLocations(summary: false)
    }

	// Class Methods
	class func create(segment: Segment, context: NSManagedObjectContext) -> RVSegment {
		return (RVSegment.get(identifier: segment.id!, inContext: context) ?? RVSegment(context: context)).update(segment: segment)
	}
	
	class func get(identifier: Int, inContext context: NSManagedObjectContext) -> RVSegment? {
		// Get the effort with the specified identifier
		if let segment : RVSegment = context.fetchObject(withKeyValue: identifier, forKey: "id") {
			return segment
		} else {			// Not found
			return nil
		}
	}
	
	func update(segment : Segment) -> RVSegment {
		self.id				= Int64(segment.id!)
		self.name			= segment.name ?? "No name"
        self.distance       = segment.distance ?? 0.0
		self.averageGrade	= segment.averageGrade ?? 0.0
		self.maxGrade		= segment.maximumGrade ?? 0.0
		self.maxElevation	= segment.elevationHigh	?? 0.0
		self.minElevation	= segment.elevationLow ?? 0.0
		self.startLat		= segment.startLatLng?.lat ?? 0.0
		self.startLong		= segment.startLatLng?.lng ?? 0.0
		self.endLat			= segment.endLatLng?.lat ?? 0.0
		self.endLong		= segment.endLatLng?.lng ?? 0.0
		self.climbCategory	= Int16(segment.climbCategory ?? 0)
		self.starred		= segment.starred ?? false
		self.elevationGain	= segment.totalElevationGain ?? ((segment.elevationHigh ?? 0.0) - (segment.elevationLow ?? 0.0))
		self.effortCount	= Int64(self.efforts.count)
		self.athleteCount	= Int64(segment.athleteCount ?? 0)

		if let _ = segment.map?.id {
			self.map		= RVMap.create(map: segment.map!, context: self.managedObjectContext!)
		} else {
			self.map = nil
		}

        self.resourceState = self.resourceState.newState(returnedState: segment.resourceState)

		// Don't change allEfforts - defaults to No
		
		return self
	}


}

// Extension to support generic table view
extension RVSegment : TableViewCompatibleEntity {
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> TableViewCompatibleCell {
		return (tableView.dequeueReusableCell(withIdentifier: "SegmentCell", for: indexPath) as! SegmentListTableViewCell).configure(withModel: self)
	}
}


// Table cell
class SegmentListTableViewCell : UITableViewCell, TableViewCompatibleCell {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var elevationLabel: UILabel!
    @IBOutlet weak var gradeLabel: UILabel!
    
	
	func configure(withModel: TableViewCompatibleEntity) -> TableViewCompatibleCell {
		if let segment = withModel as? RVSegment {
//			appLog.debug("Segment state is \(segment.resourceState.rawValue)")
            
            let segmentStarText = segment.starred ? "★" : "☆"
			
            nameLabel.text		= segmentStarText + " " + "\(segment.efforts.count) " + segment.name!
			nameLabel.textColor	= segment.resourceState.resourceStateColour
			distanceLabel.text	= segment.distance.distanceDisplayString
			gradeLabel.text	= segment.averageGrade.fixedFraction(digits: 1) + "%"
			elevationLabel.text	= segment.elevationGain.heightDisplayString
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
        
        return self
	}
}


