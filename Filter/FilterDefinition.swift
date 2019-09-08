//
//  FilterDefinition.swift
//  RideViewer
//
//  Created by West Hill Lodge on 05/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

enum FilterParamName : String, Codable {
    case from           = "From"
    case to             = "To"
    case movingTime     = "Moving"
    case totalTime      = "Total"
    case distance       = "Distance"
    case elevationGain  = "Elevation Gain"
    case averagePower   = "Av. Power"
    case totalEnergy    = "Total Energy"
}

struct FilterParam : Codable {
    var name : FilterParamName
    var group : String
    var property : String
    var comparison : FilterComparison?
    var type : FilterItemType
    
    var filterParamDisplayString : (Any)->String {
        switch self.name {
        case .distance:                 return { value in (value as! Distance).distanceDisplayString }
        case .averagePower:             return { value in (value as! Double).powerDisplayString }
        case .elevationGain:            return { value in (value as! Height).heightDisplayString }
        case .from, .to:                return { value in (value as! Date).displayString(displayType: .dateOnly, timeZone: nil) }
        case .movingTime, .totalTime:   return { value in (value as! Duration).durationDisplayString }
        case .totalEnergy:              return { value in (value as! Double).energyDisplayString }
        }
    }
}

struct FilterDefinition : Codable {
    var name : String
    var groups : [String : Int]
    var params : [FilterParam]
    
    static func read(from : String) throws -> [FilterDefinition]  {
        do {
            let appPList = try PListFile<[FilterDefinition]>(.plist("Filter", Bundle.main))
            return appPList.data
        } catch let err {
            print("Failed to parse data: \(err)")
            throw err
        }
    }
    
    static func filtersforType(_ type : String, values: FilterValues, limits: FilterValues) -> [Filter]? {
        do {
            if let filterDefinition = (try FilterDefinition.read(from: "Filter")).filter({ $0.name == type }).first {
                let y = filterDefinition.params.map { param in
                    Filter(name: param.name.rawValue,
                           group: param.group, property: param.property,
                           comparison: param.comparison,
                           filterValue: valueForParam(param, values: values),
                           filterLimit: valueForParam(param, values: limits),
                           displayFormatter: param.filterParamDisplayString)
                    
                }
                let z = y.sorted(by: { filterDefinition.groups[$1.group]! > filterDefinition.groups[$0.group]! })
                appLog.debug("Was: \(y.map { $0.group } ), Now: \(z.map { $0.group })")
                return z
            }
        } catch {
            
        }
        return nil
    }
    
    private static func valueForParam(_ param : FilterParam, values : FilterValues) -> FilterItemValue {
        switch param.type {
        case .dateType:         return .dateValue(values.dateParams[param.name.rawValue] ?? Date())
        case .doubleType:       return .doubleValue(0.0)
        case .rangeType:        return .rangeValue(values.rangeParams[param.name.rawValue] ?? RouteIndexRange(from: 0.0, to: 100.0))
        case .stringType:       return .stringValue("")
        }
    }
    
}
