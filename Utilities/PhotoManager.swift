//
//  PhotoManager.swift
//  FlightLog3
//
//  Created by Home on 29/08/2018.
//  Copyright © 2018 Phil Diggens. All rights reserved.
//
//  Manages the persistent mapping of photos to Airports, Flights and Aircraft

import Foundation
import CoreData
import Photos


class PhotoManager {
	private static var sharedManager : PhotoManager!
	class func shared() -> PhotoManager {
		if sharedManager == nil {
			sharedManager = PhotoManager()
		}
		return sharedManager
	}
	
	// MARK: Return photo assets for specified date range
	func photosForTimePeriod(_ start : Date, duration : Duration) -> [PHAsset] {
		let fetchOptions = PHFetchOptions()
		fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate =< %@", start as NSDate, (start + duration) as NSDate)
		let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
		return fetchResult.objects(at: IndexSet(integersIn: 0..<fetchResult.count))
	}
	
	// MARK: Public functions to access photos
	func getPhotoImage(localIdentifier : String, size : CGSize, resultHandler : @escaping (String, UIImage?, Date?, CLLocation?) -> Void) -> Bool {
		let assetFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
		guard assetFetchResult.count == 1 else {
			appLog.error("Zero or multiple photo assets found for local identifier \(localIdentifier)")
			return false
		}
		let asset = assetFetchResult.firstObject!
		
		DispatchQueue.global(qos: .userInitiated).async {
			let options = PHImageRequestOptions()
			options.resizeMode = .none
			options.deliveryMode = .highQualityFormat
			options.isSynchronous = true
			let _ = PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options, resultHandler: { image, infoKeys in
				DispatchQueue.main.async {
					resultHandler(asset.localIdentifier, image, asset.creationDate, asset.location)
				}
			})
		}
		return true
	}
	
}


