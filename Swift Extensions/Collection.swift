//
//  Collection.swift
//  RideViewer
//
//  Created by West Hill Lodge on 19/08/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

