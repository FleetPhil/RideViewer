//
//  RVPhotoAsset+CoreDataClass.swift
//  RideViewer
//
//  Created by Home on 18/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//
//

import Foundation
import CoreData
import Photos
import CoreLocation

@objc(RVPhotoAsset)
public class RVPhotoAsset: NSManagedObject {

	// Class Methods
	class func create(asset: PHAsset, context: NSManagedObjectContext) -> RVPhotoAsset {

		let newAsset = RVPhotoAsset.get(localIdentifier: asset.localIdentifier, inContext: context) ?? RVPhotoAsset(context: context)
		newAsset.localIdentifier = asset.localIdentifier
		newAsset.photoDate = (asset.creationDate ?? Date()) as NSDate
		newAsset.locationLat = asset.location?.coordinate.latitude ?? 0.0
		newAsset.locationLong = asset.location?.coordinate.longitude ?? 0.0
		
		return newAsset
	}
	
	class func get(localIdentifier: String, inContext context: NSManagedObjectContext) -> RVPhotoAsset? {
		// Get the asset with the specified identifier
		if let asset : RVPhotoAsset = context.fetchObject(withKeyValue: localIdentifier, forKey: "localIdentifier") {
			return asset
		} else {			// Not found
			return nil
		}
	}
	
	var coordinate : CLLocationCoordinate2D? {
		return (self.locationLat != 0.0 && self.locationLong != 0.0) ? CLLocationCoordinate2D(latitude: self.locationLat, longitude: self.locationLong) : nil
	}
}
