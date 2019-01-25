//
//  RVPhotoAsset+CoreDataProperties.swift
//  RideViewer
//
//  Created by Home on 18/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//
//

import Foundation
import CoreData


extension RVPhotoAsset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RVPhotoAsset> {
        return NSFetchRequest<RVPhotoAsset>(entityName: "RVPhotoAsset")
    }

    @NSManaged public var localIdentifier: String
	@NSManaged public var photoDate : NSDate
	@NSManaged public var locationLat : Double
	@NSManaged public var locationLong : Double
    @NSManaged public var effort: RVEffort?
    @NSManaged public var activity: RVActivity?

}
