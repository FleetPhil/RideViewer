//
//  Sort.swift
//  RideViewer
//
//  Created by West Hill Lodge on 08/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

struct SortDefinition : Codable {
    struct SortParam : Codable {
        var rank : Int
        var name : String
        var property : String
        var defaultAscending : Bool
    }
    
    var name : String
    var params : [SortParam]
    
    static func read(from : String) throws -> [SortDefinition] {
        do {
            let appPList = try PListFile<[SortDefinition]>(.plist(from, Bundle.main))
            return appPList.data
        } catch let err {
            print("Failed to parse data: \(err)")
            throw err
        }
    }
    
    static func paramsForType(_ type : String) -> [SortParam]? {
        do {
            if let sortDefinition = (try SortDefinition.read(from: "Sort")).filter({ $0.name == type }).first {
                return sortDefinition.params.sorted(by: { $0.rank < $1.rank })
            }
        } catch {
            
        }
        return nil
    }
}
