//
//  ActivityDetailViewController.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import MapKit
import Photos
import StravaSwift
import CoreData

class ActivityDetailViewController: UIViewController, ScrollingPhotoViewDelegate, RVEffortTableDelegate {
	
	//MARK: Model
	weak var activity : RVActivity!
	
	
	@IBOutlet weak var distance: UILabel!
	@IBOutlet weak var startTime: UILabel!
	
	@IBOutlet weak var elevationData: UILabel!
	@IBOutlet weak var timeData: UILabel!
	@IBOutlet weak var powerData: UILabel!
	
	@IBOutlet weak var photoView: ScrollingPhotoView!
	
	// MARK: Model for effort table
	private var effortTableViewController : RVEffortTableViewController!
	var tableDataIsComplete = false
	
	@IBOutlet weak var mapView: RideMapView! {
		didSet {
			mapView.mapType = .standard
			mapView.delegate = mapView
		}
	}
	
	// MARK: Profile View and data
	var routeViewController: RVRouteProfileViewController!

	// MARK: Photos
	private var photoAssets : [PHAsset] = []
	
	// MARK: Properties
	private var popupController : UIViewController?
	private var activityIndicator : UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard activity != nil else { return }
		
		// Set scrolling photo view delegate
		photoView?.delegate = self

		// Get Strava details
		if activity.resourceState == .detailed {
			tableDataIsComplete = true
		} else {
			startDataRetrieval()
			StravaManager.sharedInstance.updateActivity(activity, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
				if success {
					self?.endDataRetrieval()
					self?.tableDataIsComplete = true
				} else {
					self?.dataRetrievalFailed()
				}
			})
		}
		
		if activity.hasStreamOfType(.altitude) {
			self.routeViewController.setPrimaryProfile(streamOwner: activity, profileType: .altitude)
		} else {
			appLog.verbose("Getting streams")
			StravaManager.sharedInstance.streamsForActivity(activity, context: activity.managedObjectContext!, completionHandler: { [weak self] success in
				if success, let streams = self?.activity.streams {
					appLog.verbose("Streams call result: success = \(success), \(streams.count) streams")
				} else {
					appLog.verbose("Get streams failed for activity")
				}
                self?.routeViewController.setPrimaryProfile(streamOwner: self!.activity, profileType: .altitude)
			})
		}
		
		if activity != nil {
			// Populate the view fields
			updateView()
		}
	}
	
	func startDataRetrieval() {
		activityIndicator = UIActivityIndicatorView(style: .gray)
		activityIndicator.center = CGPoint(x: effortTableViewController.view.bounds.width/2, y: effortTableViewController.view.bounds.height/2)
		effortTableViewController.view.addSubview(activityIndicator)
		activityIndicator.startAnimating()
	}
	
	func endDataRetrieval() {
		activityIndicator.stopAnimating()
	}
	
	func dataRetrievalFailed() {
		activityIndicator.stopAnimating()
		// Display an alert view
		let alert = UIAlertController(title: "", message: "Unable to get Strava Update", preferredStyle: .alert)
		self.splitViewController?.present(alert, animated: true, completion: nil)
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
			alert.dismiss(animated: true, completion: nil)
		}
	}

	
	
	func updateView() {
		self.title 			= activity.name
		
		distance.text		= activity.distance.distanceDisplayString
		startTime.text		= (activity.startDate as Date).displayString(displayType: .dateTime, timeZone: activity.timeZone.timeZone)
		
		timeData.text		= "🕘 " + activity.elapsedTime.durationDisplayString
			+ " ⏱ " + activity.movingTime.durationDisplayString
			+ " ⏩ " + (activity.distance / activity.movingTime).speedDisplayString
		
		elevationData.text	= "⬇️ " + activity.lowElevation.heightDisplayString + " ⬆️ " + activity.highElevation.heightDisplayString + " ↗️ " + activity.elevationGain.heightDisplayString
		
		let powerAttributes : [NSAttributedString.Key : Any] = activity.deviceWatts ? [:] : [.foregroundColor : UIColor.lightGray]
		let powerText = NSMutableAttributedString(string: "Av:  " + String(activity.averagePower.fixedFraction(digits: 0)) + "W", attributes : powerAttributes)
		if activity.deviceWatts {
			powerText.append(NSAttributedString(string: ", Max: " + String(activity.maxPower.fixedFraction(digits: 0)) + "W"))
		}
		powerText.append(NSAttributedString(string: ", Total: " + String(activity.kiloJoules.fixedFraction(digits: 0)) + "kJ", attributes : powerAttributes))
		powerData.attributedText = powerText
		
		// Map view
		mapView!.addRoute(activity, type: .mainActivity)
		mapView!.setMapRegion()
		
		// Get photos for this activity
		//        activity.getPhotoAssets(force: false, completionHandler: { [weak self] identifiers in
		//            identifiers.forEach() { [weak self] id in
		//                if self != nil {
		//                    _ = PhotoManager.shared().getPhotoImage(localIdentifier : id.localIdentifier, size : self!.photoView.bounds.size, resultHandler : { identifier, image, creationDate, location in
		//                        self?.photoView?.addImage(image: image, identifier: identifier)
		//                    })
		//                }
		//            }
		//        })
		
		if activity.streams.filter({ $0.type == ViewProfileDataType.altitude.stravaValue }).first != nil {
			routeViewController.setPrimaryProfile(streamOwner: activity!, profileType: .altitude)
		} else {
			StravaManager.sharedInstance.streamsForActivity(activity, context: activity.managedObjectContext!, completionHandler: { (success) in
				self.activity.managedObjectContext?.saveContext()
				self.routeViewController.setPrimaryProfile(streamOwner: self.activity!, profileType: .altitude)
			})
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if activity != nil {
			mapView.setMapRegion()
		}
	}
	
	func imageHandler(identifier: String, image : UIImage?, photoDate: Date?, location: CLLocationCoordinate2D) {
		// appLog.debug("Returned image \(identifier)")
		photoView.addImage(image: image, identifier: identifier)
	}
	
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? SegmentDetailViewController {
//			destination.segment = dataManager.objectAtIndexPath(tableView.indexPathForSelectedRow!)?.segment
		}
		// Embed segues
		if let destination = segue.destination as? RVRouteProfileViewController {
			self.routeViewController = destination
		}
		if let destination = segue.destination as? RVEffortTableViewController {
			effortTableViewController = destination
			effortTableViewController.delegate = self
			effortTableViewController.ride = activity
		}
	}
	
	// MARK: Effort table delegate
	func didSelectEffort(effort: RVEffort) {
		mapView.addRoute(effort, type: .highlightSegment)
		routeViewController.setHighLightRange(effort.indexRange)
	}
	
	func didDeselectEffort(effort: RVEffort) {
		mapView.setTypeForRoute(effort, type: nil)
	}
	
	// MARK: Scrolling photo view delegate
	func photoDidChangeToIndex(_ index: Int) {
		activity.getPhotoAssets(force: false, completionHandler: { [weak self] assets in
			let selectedPhotoAsset = assets[index]
			_ = PhotoManager.shared().getPhotoImage(localIdentifier: selectedPhotoAsset.localIdentifier,
													size: CGSize(width: 30, height: 30),
													resultHandler: { [ weak self]  _, image, _, location in
														self?.mapView.addPhoto(image: image, location: location)
			})
		})
	}
}
