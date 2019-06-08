//
//  ActivityDetailViewController.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import MapKit
import StravaSwift
import CoreData

class ActivityDetailViewController: UIViewController, RVEffortTableDelegate {

    //MARK: Model
	weak var activity : RVActivity!
	
	@IBOutlet weak var infoButton: UIBarButtonItem!
	
	@IBOutlet weak var distance: UILabel!
	@IBOutlet weak var startTime: UILabel!
	
	@IBOutlet weak var elevationData: UILabel!
	@IBOutlet weak var timeData: UILabel!
	@IBOutlet weak var powerData: UILabel!
	
	// MARK: Model for effort table
	private var effortTableViewController : RVEffortListViewController!
	var tableDataIsComplete = false
	
	@IBOutlet weak var mapView: RideMapView! {
		didSet {
			mapView.mapType = .standard
			mapView.delegate = mapView
		}
	}
	
	// MARK: Profile View and data
	var routeViewController: RVRouteProfileViewController!
	
	// MARK: Properties
	private var activityIndicator : UIActivityIndicatorView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let activity = activity else { return }
		
		// Info button disabled as no effort selected
		infoButton.isEnabled = false
        
		// Get detailed activity information (also includes segment efforts)
        startDataRetrieval()
        activity.detailedActivity(completionHandler: { [weak self] detailedActivity in
            appLog.verbose("Returned \(detailedActivity == nil ? "nil" : "values") for activity \(self?.activity.name ?? "(nil self)")")
            if detailedActivity != nil {
                self?.endDataRetrieval()
                self?.updateView()
            } else {
                self?.dataRetrievalFailed()
                self?.updateView()
            }
        })
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		// If change is to compact width the effort table will reappear - so scroll to selected row if it exists
		// If change is to regular width disable the info button as the efforts are not visible
		switch traitCollection.verticalSizeClass {
		case .compact:
			infoButton.isEnabled = false
		case .regular:
			effortTableViewController.highlightEffort(selectedEffort)
			infoButton.isEnabled = (selectedEffort != nil)
		default:
			break
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
			+ " ⏩ " + (activity.distance / activity.movingTime).speedDisplayString()
		
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
        
        // Set the altitude profile - will retrieve data from Strava if not on the database
        self.routeViewController.setPrimaryProfile(streamOwner: self.activity, profileType: .altitude, seriesType: .distance)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if activity != nil {
			mapView.setMapRegion()
		}
	}
	
	// MARK: - Navigation
	var selectedEffort : RVEffort? = nil
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? EffortAnalysisViewController {
			destination.segment = selectedEffort?.segment
			destination.selectedEffort = selectedEffort
		}
		// Embed segues
		if let destination = segue.destination as? RVRouteProfileViewController {
			self.routeViewController = destination
		}
		if let destination = segue.destination as? RVEffortListViewController {
			effortTableViewController = destination
			effortTableViewController.delegate = self
			effortTableViewController.ride = activity
		}
	}
	
	// MARK: Effort table delegate
	func didSelectEffort(effort: RVEffort) {
		mapView.addRoute(effort, type: .highlightSegment)
		mapView.zoomToRoute(effort)
		
		routeViewController.profileChartView.setHighLightRange(effort.distanceRangeInActivity)
		
		selectedEffort = effort
		infoButton.isEnabled = true
	}
	
	func didDeselectEffort(effort: RVEffort) {
		routeViewController.profileChartView.setHighLightRange(nil)		// Deselects highlights
		selectedEffort = nil
		
		mapView.setTypeForRoute(effort, type: nil)
		infoButton.isEnabled = false
	}
	
}
