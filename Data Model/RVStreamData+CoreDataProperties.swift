//
//  RVStreamData+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 25/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVStreamData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVStreamData> {
        return NSFetchRequest<RVStreamData>(entityName: "RVStreamData")
    }

	@NSManaged public var index: Int64
    @NSManaged public var dataPoint: Double
    @NSManaged public var stream: RVStream

}
