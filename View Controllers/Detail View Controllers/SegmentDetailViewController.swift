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
            segment.detailedSegment(completionHandler: { [weak self] segment in
                self?.updateView()
            })
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
        }
        
        // Get all efforts for this segment - any updates will be automatically applied to the effort table
        segment.efforts(completionHandler: ({ [weak self] efforts in
            if self != nil {
                appLog.verbose("\(efforts?.count ?? -1) efforts retrieved for segment \(self!.segment.name!)")
            }
        }))
        
        // Get the altitude profile
        segment.streams(completionHandler: { [weak self] streams in
            // Get the route altitude profile
            if self != nil {
                self!.routeViewController.setPrimaryProfile(streamOwner: self!.segment, profileType: .altitude, seriesType: .distance)
            }
        })
    }
	
	var selectedEffort : RVEffort? = nil
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? EffortAnalysisViewController  {
			destination.segment = segment
            destination.selectedEffort = selectedEffort
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

