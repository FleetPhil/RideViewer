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


enum SegmentSort : String, CaseIterable {
    case name           = "name"
    case distance       = "distance"
    case averageGrade   = "averageGrade"
    case effortCount    = "effortCount"
    
    var selectionLabel : String {
        switch self {
        case .name:             return "Name"
        case .distance:         return "Distance"
        case .averageGrade:     return "Av. Grade"
        case .effortCount:      return "Rides"
        }
    }
    
    var defaultAscending : Bool {
        switch self {
        case .name:             return true
        case .distance:         return false
        case .averageGrade:     return false
        case .effortCount:      return false
        }
    }
}

enum SegmentFilter  {
    case cycleRide(Bool)
    case virtualRide(Bool)
    case walk(Bool)
    case other(Bool)
    case shortRide(Bool)
    case longRide(Bool)
    case startDate(Date)
    
    var selectionLabel: String {
        switch self {
        case .cycleRide:          return "Cycle Rides"
        case .virtualRide:        return "Virtual Rides"
        case .walk:               return "Walks"
        case .other:              return "Other Activities"
        case .shortRide:          return "Short Rides"
        case .longRide:           return "Long Rides"
        case .startDate:          return "Start Date"
        }
    }
    
    var selectionValue: PopupSelectionValue {
        get {
            switch self {
            case .startDate(let date) :     return .typeDate(date: date)
            case .cycleRide(let bool),
                 .longRide(let bool),
                 .other(let bool),
                 .shortRide(let bool),
                 .virtualRide(let bool),
                 .walk(let bool): return .typeBool(bool: bool)
            }
        }
    }
    
    // Initial filter defaults if they cannot be retrieved on the first run
//    static var selectionDefaults : [ ActivityFilter ] {
//        return [
//            .cycleRide(true), .longRide(true), .other(false), .shortRide(false), .virtualRide(false), .walk(false),
//            .startDate(Calendar.current.date(byAdding: .year, value: -1, to: Date())!)
//        ]
//    }
    
    var popupGroup: String {
        switch self {
        case .cycleRide, .virtualRide, .walk, .other:        return "Activity Type"
        case .longRide, .shortRide:                            return "Ride Length"
        case .startDate:                                    return "Date"
        }
    }
    
    func predicateForFilterOption() -> NSPredicate {
        let longRideLimit = Settings.sharedInstance.activityMinDistance
        switch self {
        case .cycleRide:        return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Ride.rawValue])
        case .virtualRide:        return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.VirtualRide.rawValue])
        case .walk:                return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Walk.rawValue])
        case .other:            return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Workout.rawValue])
        case .longRide:         return NSPredicate(format: "distance >= %f",     argumentArray: [longRideLimit])
        case .shortRide:        return NSPredicate(format: "distance < %f",     argumentArray: [longRideLimit])
        // TODO: Dummy
        case .startDate:        return NSPredicate(format: "", argumentArray: nil)
        }
    }
    
    static func predicateForFilters(_ filters : [SegmentFilter]) -> NSCompoundPredicate {
        var predicates : [NSCompoundPredicate] = []
        let filterGroups = Dictionary(grouping: filters, by: { $0.popupGroup })
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
	
	// Helper functions
	func shortestElapsedEffort() -> RVEffort? {
		return self.efforts.min(by: { $0.elapsedTime < $1.elapsedTime } )
	}
}

// Extensions to return Strava data
extension RVSegment {
    /**
     Get detailed segment
     
     Calls completion handler with nil if data not available
     
     - Parameters:
     - completionHandler: function called with the returned streams
     - Returns: none
     */
    func detailedSegment(completionHandler : (@escaping (RVSegment?)->Void)) {
        if self.resourceState == .detailed {
            completionHandler(self)
            return
        }
        
        StravaManager.sharedInstance.getSegmentDetails(self, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
            if success {
                completionHandler(self)
            } else {
                completionHandler(nil)
            }
        })
    }
    
    /**
     Get streams for this segment
     
     Calls completion handler with nil data not available
     
     - Parameters:
     - completionHandler: function called with the returned streams
     - Returns: none
     */
    func streams(completionHandler : (@escaping (Set<RVStream>?)->Void)) {
        if self.streams.count > 0 {
            completionHandler(self.streams)
            return
        }
        StravaManager.sharedInstance.streamsForSegment(self, context: self.managedObjectContext!, completionHandler: { success in
            if (success) {
                self.managedObjectContext?.saveContext()
                completionHandler(self.streams)
            } else {
                completionHandler(nil)
            }
        })
    }

    
    /**
     Get efforts for this segment
     
     Calls completion handler with nil data not available
     
     - Parameters:
        - completionHandler: function called with the returned efforts
     - Returns: none
     */
    func efforts(completionHandler : (@escaping (_ efforts : Set<RVEffort>?)->Void)) {
        if self.allEfforts {                // We have all efforts so no need to get from Strava
            completionHandler(self.efforts)
            return
        }
        StravaManager.sharedInstance.effortsForSegment(self, page: 1, context: self.managedObjectContext!, completionHandler: { [weak self] success in
            if (success) {
                self?.allEfforts = true
                self?.managedObjectContext?.saveContext()
                completionHandler(self?.efforts)
            } else {
                completionHandler(nil)
            }
        })
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

extension RVSegment {
    static var sortParams : [PopupItem] = [
        PopupItem(label: "Name", group: nil, value: .typeBool(bool: true), criteria: .sortCriteria(NSSortDescriptor(key: "name", ascending: true))),
        PopupItem(label: "Distance", group: nil, value: .typeBool(bool: false), criteria: .sortCriteria(NSSortDescriptor(key: "distance", ascending: false))),
        PopupItem(label: "Av. Grade", group: nil, value: .typeBool(bool: false), criteria: .sortCriteria(NSSortDescriptor(key: "averageGrade", ascending: false))),
        PopupItem(label: "Rides", group: nil, value: .typeBool(bool: false), criteria: .sortCriteria(NSSortDescriptor(key: "effortCount", ascending: false)))
    ]
    
    static var filterParams : [PopupItem] = [
        PopupItem(label: "Only Starred", group: "Starred", value: .typeBool(bool: false), criteria: .filterCriteria("starred == %@")),
        PopupItem(label: "Flat", group: "Profile", value: .typeBool(bool: true), criteria: .filterCriteria("averageGrade = 0")),
        PopupItem(label: "Ascending", group: "Profile", value: .typeBool(bool: true), criteria: .filterCriteria("starred == %@")),
        PopupItem(label: "Descending", group: "Profile", value: .typeBool(bool: true), criteria: .filterCriteria("starred == %@"))

    ]
}

//enum SegmentFilter : String, CaseIterable {
//    case starred            = "Only Starred"
//    case short                = "Short"
//    case long                = "Long"
//    case flat                = "Flat"
//    case ascending            = "Ascending"
//    case descending            = "Descending"
//    case singleEffort        = "Single Effort"
//    case multipleEfforts    = "Multiple Effort"
//
//    var selectionLabel: String {
//        return self.rawValue
//    }
//
//    var popupGroup: String {
//        switch self {
//        case .starred:                          return "Starred"
//        case .short, .long:                     return "Segment Length"
//        case .flat, .ascending, .descending:    return "Profile"
//        case .multipleEfforts, .singleEffort:     return "Number of Efforts"
//        }
//    }
//
//    func predicateForFilterOption() -> NSPredicate {
//        let longLimit = Settings.sharedInstance.segmentMinDistance
//        switch self {
//        case .starred:          return NSPredicate(format: "starred == %@", NSNumber(value: true))
//        case .short:            return NSPredicate(format: "distance < %f", argumentArray: [longLimit])
//        case .long:                return NSPredicate(format: "distance >= %f", argumentArray: [longLimit])
//        case .flat:                return NSPredicate(format: "averageGrade = 0", argumentArray: nil)
//        case .ascending:        return NSPredicate(format: "averageGrade > 0", argumentArray: nil)
//        case .descending:        return NSPredicate(format: "averageGrade < 0", argumentArray: nil)
//        case .multipleEfforts:    return NSPredicate(format: "effortCount > 1", argumentArray: nil)
//        case .singleEffort:        return NSPredicate(format: "effortCount = 1", argumentArray: nil)
//        }
//    }



