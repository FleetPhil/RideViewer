//
//  Filter.swift
//  RideViewer
//
//  Created by West Hill Lodge on 02/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation


enum FilterComparison : String {
    case greaterThan        = " > "
    case lessThan           = " < "
    case greaterOrEqual     = " >= "
    case lessOrEqual        = " <= "
}

enum FilterSelectionType {
    case date((String, FilterComparison, Date))         // Property, comparison, value
    case range((String, RouteIndexRange))               // Property, Range
    case value((String, FilterComparison, Double))      // Property, comparison, value
    case string((String, String))
}

struct Filter {
    var name : String           // Name to show on selection table
    var group : String          // Name of section in selection table
    var type : FilterSelectionType
    
    /// return a NSPredicate for this filter
    func predicateForFilter() -> NSPredicate {
        switch self.type {
        case .range(let (property, range)):
            let minimumPredicate = NSPredicate(format: "\(property) >= %f", range.from)
            let maximumPredicate = NSPredicate(format: "\(property) <= %f", range.to)
            return NSCompoundPredicate(andPredicateWithSubpredicates: [minimumPredicate, maximumPredicate])
        case .value(let (property, comparison, value)):
            return NSPredicate(format: property + comparison.rawValue + "%f", argumentArray: [value])
        case .date(let (property, comparison, value)):
            return NSPredicate(format: property + comparison.rawValue + "%@", argumentArray: [value])
        case .string(let (property, value)):
            return NSPredicate(format: property + " = %@", argumentArray: [value])
        }
    }

    static func predicateForFilters(_ filters : [Filter]) -> NSCompoundPredicate {
        var predicates : [NSCompoundPredicate] = []
        let filterGroups = Dictionary(grouping: filters, by: { $0.group })
        for group in filterGroups {
            let subPred = group.value.map({ $0.predicateForFilter() })
            let groupPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPred)
            predicates.append(groupPredicate)
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}


