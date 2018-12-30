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

@objc(RVSegment)
public class RVSegment: NSManagedObject {
	// Class Methods
	class func create(segment: Segment, context: NSManagedObjectContext) -> RVSegment {
		return (RVSegment.get(identifier: segment.id!, inContext: context) ?? RVSegment(context: context)).update(segment: segment)
	}
	
	class func get(identifier: Int, inContext context: NSManagedObjectContext) -> RVSegment? {
		// Get the effort with the specified identifier
		if let segment = context.fetchObjectForEntityName(RVSegment.entityName, withKeyValue: identifier, forKey: "id") as! RVSegment? {
			return segment
		} else {			// Not found
			return nil
		}
	}
	
	func update(segment : Segment) -> RVSegment {
		self.id				= Int64(segment.id!)
		self.name			= segment.name ?? "No name"
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
		self.elevationGain	= segment.totalElevationGain ?? 0.0
		self.effortCount	= Int64(segment.effortCount ?? 0)
		self.athleteCount	= Int64(segment.athleteCount ?? 0)
		
		let resourceStateValue 		= Int16(segment.resourceState != nil ? segment.resourceState!.rawValue : 0)
		self.resourceState			= ResourceState(rawValue: resourceStateValue) ?? .undefined
		
		return self
	}


}

// Extension to support generic table view
extension RVSegment : TableViewCompatible {
	var reuseIdentifier: String {
		return "SegmentCell"
	}
	
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell {
		if let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath) as? SegmentListTableViewCell {
			cell.configure(withModel: self)
			return cell
		} else {
			appLog.error("Unable to dequeue cell")
			return UITableViewCell()
		}
	}
}

// Table cell
class SegmentListTableViewCell : UITableViewCell {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var effortLabel: UILabel!
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var elevationLabel: UILabel!
	
	func configure(withModel: NSManagedObject) {
		if let segment = withModel as? RVSegment {
			appLog.debug("Segment state is \(segment.resourceState.rawValue)")
			
			nameLabel.text		= segment.name
			distanceLabel.text	= segment.distance.distanceDisplayString
			effortLabel.text	= "\(segment.effortCount)"
			elevationLabel.text	= segment.elevationGain.heightDisplayString
			
			self.separatorInset = .zero
		} else {
			appLog.error("Unexpected entity for table view cell")
		}
	}
}


