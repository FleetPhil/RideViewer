//
//  ScanPhotosViewController.swift
//  RideViewer
//
//  Created by Home on 19/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData
import Photos

class ScanPhotosViewController: UIViewController {
	
	var stopScan : Bool = false
	var totalPhotosCount : Int = 0
	var scannedPhotosCount : Int = 0
	var activitiesMatchedCount : Int = 0
	var effortsMatchedCount : Int = 0
	var photosStoredCount : Int = 0
	
	@IBOutlet weak var totalPhotosLabel: UILabel!
	@IBOutlet weak var photosscannedLabel: UILabel!
	@IBOutlet weak var activitiesMatchedLabel: UILabel!
	@IBOutlet weak var effortsMatchedLabel: UILabel!
	@IBOutlet weak var photosStoredLabel: UILabel!
	@IBOutlet weak var startButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		updateLabels()
		
		startButton.setTitle("Start scan", for: .normal)
    }
	
	func updateLabels() {
		if Thread.isMainThread {
			setLabelText()
		} else {
			DispatchQueue.main.sync {
				setLabelText()
			}
		}
	}
	
	func setLabelText() {
		totalPhotosLabel.text 		= "\(totalPhotosCount) total photos"
		photosscannedLabel.text		= "\(scannedPhotosCount) photos scanned"
		activitiesMatchedLabel.text = "\(activitiesMatchedCount) activities scanned"
		effortsMatchedLabel.text 	= "\(effortsMatchedCount) segment efforts matched"
		photosStoredLabel.text		= "\(photosStoredCount) photos stored"
	}
	
	@IBAction func startScanButton(_ sender: UIButton!) {
		if sender.title(for: .normal) == "Stop scan" {
			stopScan = true
			startButton.setTitle("Stopping", for: .normal)
			return
		}
		
		/// Load Photos
		PHPhotoLibrary.requestAuthorization { [ weak self] (status) in
			switch status {
			case .authorized:
				appLog.debug("Photos authorised")
				DispatchQueue.main.sync {
					self?.startButton.setTitle("Stop scan", for: .normal)
				}
				self?.getPhotosForActivities()
				DispatchQueue.main.sync {
					self?.startButton.setTitle("Start scan", for: .normal)
				}
			case .denied, .restricted:
				appLog.debug("Photo access not allowed")
			case .notDetermined:
				appLog.debug("Photo access not determined")
			}
		}
	}
	
	func getPhotosForActivities() {
		let allActivities : [RVActivity] = CoreDataManager.sharedManager().viewContext.fetchObjects()!
		for activity in allActivities {
			if stopScan { break }
			activity.getPhotoAssets(force: true, completionHandler: { photoAssets in
				self.photosStoredCount += photoAssets.count
				self.activitiesMatchedCount += 1
				self.updateLabels()
			})
		}
	}
}
