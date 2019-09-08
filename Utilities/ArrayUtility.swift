//
//  ArrayUtility.swift
//  RideViewer
//
//  Created by West Hill Lodge on 07/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

func twoDimensionalArray<T>(_ input : [T], sameGroup : ((T, T) -> Bool)) -> [[T]] {
    var output = [[T]]()
    var currentGroup = [T]()
    
    input.forEach { (item) in
        if currentGroup.isEmpty {        // First item
            currentGroup = [item]
        } else {
            if sameGroup(item, currentGroup.last!) {         // If item is in the same group as the last one
                currentGroup.append(item)
            } else {                                // Not same group
                output.append(currentGroup)
                currentGroup = [item]
            }
        }
    }
    output.append(currentGroup)
    return output
}
