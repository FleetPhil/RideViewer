//
//  Filter.swift
//  RideViewer
//
//  Created by West Hill Lodge on 30/05/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import StravaSwift

enum Filter : String, PopupSelectable, CaseIterable {
    case cycleRide          = "Cycle Rides"
    case virtualRide        = "Virtual Rides"
    case walk               = "Walks"
    case other              = "Other Activities"
    case shortRide          = "Short Rides"
    case longRide           = "Long Rides"
    
    var displayString: String { return self.rawValue }
    
    var filterGroup: String {
        switch self {
        case .cycleRide, .virtualRide, .walk, .other:        return "Activity Type"
        case .longRide, .shortRide:                          return "Ride Length"
        }
    }
    
    func predicateForFilterOption() -> NSPredicate {
        let longRideLimit = Settings.sharedInstance.activityMinDistance
        switch self {
        case .cycleRide:        return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Ride.rawValue])
        case .virtualRide:        return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.VirtualRide.rawValue])
        case .walk:                return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Walk.rawValue])
        case .other:            return NSPredicate(format: "activityType = %@", argumentArray: [ActivityType.Workout.rawValue])
        case .longRide:            return NSPredicate(format: "distance >= %f",     argumentArray: [longRideLimit])
        case .shortRide:        return NSPredicate(format: "distance < %f",     argumentArray: [longRideLimit])
        }
    }
    
    static func predicateForFilters(_ filters : [Filter]) -> NSCompoundPredicate {
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
