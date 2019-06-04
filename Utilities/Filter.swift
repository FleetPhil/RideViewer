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

    case starred            = "Only Starred"

    case short                = "Short"
    case long                = "Long"

    case flat                = "Flat"
    case ascending            = "Ascending"
    case descending            = "Descending"

    case singleEffort        = "Single Effort"
    case multipleEfforts    = "Multiple Effort"
    
    var displayString: String { return self.rawValue }
    
    var filterGroup: String {
        switch self {
        case .cycleRide, .virtualRide, .walk, .other:        return "Activity Type"
        case .starred:                          return "Starred"
        case .short, .long:                     return "Length"
        case .flat, .ascending, .descending:    return "Profile"
        case .multipleEfforts, .singleEffort:     return "Number of Efforts"

        }
    }
    
    static func predicateForFilters(_ filters : [Filter]) -> NSCompoundPredicate {
        var predicates : [NSCompoundPredicate] = []
        let filterGroups = Dictionary(grouping: filters, by: { $0.filterGroup })
        for group in filterGroups {
            let subPred = group.value.map({ $0.predicateForFilter() })
            let groupPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: subPred)
            predicates.append(groupPredicate)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}





