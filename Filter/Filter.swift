//
//  Filter.swift
//  RideViewer
//
//  Created by West Hill Lodge on 02/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

protocol FilterDelegate {
    func newFilters(_ filters : [Filter]?)
}

enum FilterComparison : String, Codable {
    case greaterThan        = " > "
    case lessThan           = " < "
    case greaterOrEqual     = " >= "
    case lessOrEqual        = " <= "
    case equal              = " = "
}

enum FilterItemType : String, Codable {
    case dateType
    case rangeType
    case doubleType
    case stringType
}

enum FilterItemValue : Codable {
    case dateValue(Date)
    case rangeValue(RouteIndexRange)
    case doubleValue(Double)
    case stringValue(String)
    
    enum CodingKeys: CodingKey {
        case date, range, value, string
    }
    
    enum ValidationError : Error {
        case invalidData
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(Date.self, forKey: .date) {
            self = .dateValue(value)
            return
        } else if let value = try? values.decode(RouteIndexRange.self, forKey: .range) {
            self = .rangeValue(value)
            return
        } else if let value = try? values.decode(Double.self, forKey: .value) {
            self = .doubleValue(value)
            return
        } else if let value = try? values.decode(String.self, forKey: .string) {
            self = .stringValue(value)
            return
        } else {
            throw ValidationError.invalidData
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .dateValue(let value):
            try container.encode(value, forKey: .date)
        case .rangeValue(let value):
            try container.encode(value, forKey: .range)
        case .doubleValue(let value):
            try container.encode(value, forKey: .value)
        case .stringValue(let value):
            try container.encode(value, forKey: .string)
        }
    }
    
}

struct Filter  {
    var name : String           // Name to show on selection table
    var group : String          // Name of section in selection table
    var property : String       // Core data property
    var comparison : FilterComparison?
    var filterValue : FilterItemValue
    var filterLimit : FilterItemValue?
    var displayFormatter : ((Double)->String)
    
    /// return a NSPredicate for this filter
    func predicateForFilter() -> NSPredicate {
        switch self.filterValue {
        case .rangeValue(let range):
            let minimumPredicate = NSPredicate(format: "\(property) >= %f", range.from)
            let maximumPredicate = NSPredicate(format: "\(property) <= %f", range.to)
            return NSCompoundPredicate(andPredicateWithSubpredicates: [minimumPredicate, maximumPredicate])
        case .doubleValue(let value):
            return NSPredicate(format: property + (comparison ?? .equal).rawValue + "%f", argumentArray: [value])
        case .dateValue(let value):
            return NSPredicate(format: property + (comparison ?? .equal).rawValue + "%@", argumentArray: [value])
        case .stringValue(let value):
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
    
    mutating func resetValue() {
        if let limit = self.filterLimit {
            self.filterValue = limit
        }
    }
}

struct FilterValues : Codable {
    var dateParams : [String : Date]
    var rangeParams : [String : RouteIndexRange]
}

func valuesForFilters(_ filters : [Filter]) -> FilterValues {
    var values = FilterValues(dateParams: [:], rangeParams: [:])
    
    filters.forEach { (filter) in
        switch filter.filterValue {
        case .dateValue(let dateValue):
            values.dateParams[filter.name] = dateValue
        case .rangeValue(let rangeValue):
            values.rangeParams[filter.name] = rangeValue
        default:
            fatalError("Values for filters")
        }
    }
    return values
}

// MARK: Save and restore filter values
func saveFilterValues(filterValues : FilterValues, key: String) {
    let encoder = JSONEncoder()
    
    if let encoded = try? encoder.encode(filterValues) {
        UserDefaults.standard.set(encoded, forKey: key)
    }
}

func savedFilterValues(key: String) -> FilterValues? {
    if let savedFilters = UserDefaults.standard.object(forKey: key) as? Data {
        let decoder = JSONDecoder()
        if let filters = try? decoder.decode(FilterValues.self, from: savedFilters) {
            return filters
        }
    }
    return nil
}




