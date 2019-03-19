//
//  SegmentAnalysisViewController.swift
//  RideViewer
//
//  Created by Home on 10/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class SegmentAnalysisViewController: UIViewController, RVEffortTableDelegate {
	
	@IBOutlet weak var topInfoLabel: UILabel!
	@IBOutlet weak var bottomInfoLabel: UILabel!
	
	private var effortTableViewController : RVEffortListViewController!
	private var speedProfileController : RVRouteProfileViewController!
	private var powerProfileController : RVRouteProfileViewController!
	private var HRProfileController : RVRouteProfileViewController!
	
	// Model
	var segment : RVSegment! {
		didSet {
			shortestElapsed = segment.shortestElapsedEffort()
		}
	}
	
	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	private var effortFilters : [EffortFilter] = []
	private var effortSort : EffortSort = .elapsedTime
	private var popupController : UIViewController?
	
	// MARK: Properties
	private var shortestElapsed : RVEffort?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.title = segment.name!
		topInfoLabel.text = "Fastest: \(shortestElapsed?.activity.name ?? "Unknown")"
		topInfoLabel.textColor = ViewProfileDisplayType.primary.displayColour
		
		// Get stream data for the fastest ride on this segment and set as the primary
		if shortestElapsed != nil {
			displayStreamsForEffort(shortestElapsed!, displayType: .primary)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVRouteProfileViewController {
			switch segue.identifier {
			case "SpeedProfileSegue":	speedProfileController = destination
			case "PowerProfileSegue":	powerProfileController = destination
			case "HRProfileSegue":		HRProfileController = destination
			default:					appLog.error("Unknown profile segue identifier \(segue.identifier!)")
			}
		}

		if let destination = segue.destination as? RVEffortListViewController {
			effortTableViewController = destination
			effortTableViewController.delegate = self
			effortTableViewController.ride = segment
		}
	}
	
	// MARK: Effort table delegate
	func didSelectEffort(effort: RVEffort) {
		displayStreamsForEffort(effort, displayType: .secondary)
	}
	
	func didDeselectEffort(effort: RVEffort) {
		speedProfileController.removeSecondaryProfile(owner: effort)
		powerProfileController.removeSecondaryProfile(owner: effort)
		HRProfileController.removeSecondaryProfile(owner: effort)
	}
	
	// MARK: Effort profile setup
	private func displayStreamsForEffort(_ effort: RVEffort, displayType: ViewProfileDisplayType) {
		if effort.hasStreamOfType(.distance) {			// Has axis value
			setProfilesForEffort(effort, displayType: displayType)
		} else {
			StravaManager.sharedInstance.streamsForEffort(effort, context: effort.managedObjectContext!, completionHandler: { [weak self] (success) in
				if success {
					effort.managedObjectContext!.saveContext()
					self?.setProfilesForEffort(effort, displayType: displayType)
				} else {
					appLog.verbose("Failed to get streams for effort \(effort.activity.name)")
				}
			})
		}
	}
	
	private func setProfilesForEffort(_ effort : RVEffort, displayType: ViewProfileDisplayType) {
		switch displayType {
		case .primary:
			speedProfileController.setPrimaryProfile(streamOwner: effort, profileType: .speed)
			powerProfileController.setPrimaryProfile(streamOwner: effort, profileType: .power)
			HRProfileController.setPrimaryProfile(streamOwner: effort, profileType: .heartRate)
		case .secondary:
			speedProfileController.addSecondaryProfile(owner: effort, profileType: .speed)
			powerProfileController.addSecondaryProfile(owner: effort, profileType: .power)
			HRProfileController.addSecondaryProfile(owner: effort, profileType: .heartRate)
		default:
			appLog.error("Unexpected display type \(displayType) requested")
			break
		}
	}
}



