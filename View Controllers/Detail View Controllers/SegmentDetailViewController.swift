//
//  SegmentDetailViewController.swift
//  RideViewer
//
//  Created by Home on 05/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData
import StravaSwift

class SegmentDetailViewController: UIViewController, RVEffortTableDelegate {
	
    //MARK: Model
    var segment : RVSegment!
    
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var elevationLabel: UILabel!
	
    @IBOutlet weak var mapView: RideMapView! {
        didSet {
            mapView.mapType = .standard
            mapView.delegate = mapView
        }
    }

	private var effortTableViewController : RVEffortListViewController!
    @IBOutlet weak var routeViewController: RVRouteProfileViewController!
	
	private var popupController : UIViewController?
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if segment != nil {
            updateView()
        }
    }
    
    func updateView() {
		let segmentStarText = segment.starred ? "★" : "☆"
        self.title 				= segmentStarText + " " + segment.name!
        
		distanceLabel.text = segment.distance.distanceDisplayString
		elevationLabel.text	= " ↗️ " + segment.elevationGain.heightDisplayString + " " + segment.averageGrade.fixedFraction(digits: 1) + "%"
		
		// Update map
        if segment.map != nil {
			self.mapView.addRoute(segment, type: .highlightSegment)
		} else {
            // Get segment details including route
            StravaManager.sharedInstance.getSegmentDetails(segment, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
                guard self != nil else { return }
                if success {
                    self!.mapView!.addRoute(self!.segment, type: .highlightSegment)
				} else {		// If route not found will zoom to start/end annotations
					self?.mapView.addRoute(self!.segment, type: .highlightSegment)
				}
            })
        }
        
        // Get all efforts for this segment - any updates will be automatically applied to the effort table
        self.segment.efforts(completionHandler: ({ [weak self] efforts in
            if self != nil {
                appLog.verbose("\(efforts?.count ?? -1) efforts retrieved for segment \(self!.segment.name!)")
            }
        }))
		
		// Get the route altitude profile
        routeViewController.setPrimaryProfile(streamOwner: segment, profileType: .altitude, seriesType: .distance)
        appLog.verbose("Getting streams")
        StravaManager.sharedInstance.streamsForSegment(segment, context: segment.managedObjectContext!, completionHandler: { [weak self] success in
            if success, let streams = self?.segment.streams {
                appLog.verbose("Streams call result: success = \(success), \(streams.count) streams")
            } else {
                appLog.verbose("Get streams failed for activity")
            }
            _ = self?.routeViewController.setPrimaryProfile(streamOwner: self!.segment, profileType: .altitude, seriesType: .distance)
        })
    }
	
	var selectedEffort : RVEffort? = nil
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? SegmentAnalysisViewController {
			destination.segment = segment
			destination.highlightEffort = selectedEffort
			return
		}
		
		// Embed segues
		if let destination = segue.destination as? RVRouteProfileViewController {
			self.routeViewController = destination
			return
		}
		if let destination = segue.destination as? RVEffortListViewController {
			effortTableViewController = destination
			effortTableViewController.delegate = self
			effortTableViewController.ride = segment
		}
	}
		
	// MARK: Effort table delegate
	func didSelectEffort(effort: RVEffort) {
		appLog.verbose("Selected \(effort.activity.name)")
		selectedEffort = effort
	}
	
	func didDeselectEffort(effort: RVEffort) {
		appLog.verbose("Deselected \(effort.activity.name)")
		selectedEffort = nil
	}
}

