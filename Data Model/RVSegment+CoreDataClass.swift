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
	
	var displayString : String {           // Text to use when choosing item
		switch self {
		case .name:			return "Name"
		case .distance:		return "Distance"
		case .grade:		return "Av. Grade"
		}
	}
    
    var defaultAscending : Bool {           //
        switch self {
        case .name:            return true
        case .distance:        return false
        case .grade:           return false
        }
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
		self.effortCount	= Int64(segment.effortCount ?? 0)
		self.athleteCount	= Int64(segment.athleteCount ?? 0)

		if let _ = segment.map?.id {
			self.map		= RVMap.create(map: segment.map!, context: self.managedObjectContext!)
		} else {
			self.map = nil
		}

        self.resourceState = self.resourceState.newState(returnedState: segment.resourceState)

		self.allEfforts				= false
		
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
			
            nameLabel.text		= "\(segment.efforts.count) " + segment.name!
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


