//
//  RVStreamData+CoreDataClass.swift
//  RideViewer
//
//  Created by Home on 25/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//
//

import Foundation
import CoreData
import StravaSwift

@objc(RVStreamData)
public class RVStreamData: NSManagedObject {
	// Class Methods
	class func create(stream: RVStream, index : Int, dataPoint : Double, context: NSManagedObjectContext) -> RVStreamData {
		let streamData = RVStreamData(context: context)
		streamData.stream = stream
		streamData.index = Int64(index)
		streamData.dataPoint = dataPoint
		return streamData
	}
}

