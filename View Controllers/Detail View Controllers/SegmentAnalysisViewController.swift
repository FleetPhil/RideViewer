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
		getStreams(effort: effort)
	}
	
	func didDeselectEffort(effort: RVEffort) {
		appLog.verbose("Deselected \(effort.activity.name)")
	}
	
	// MARK: Effort profile setup
	private func getStreams(effort: RVEffort) {
		if effort.hasStreamOfType(.speed) {
			setProfilesForEffort(effort)
		} else {
			StravaManager.sharedInstance.streamsForEffort(effort, context: effort.managedObjectContext!, completionHandler: { [weak self] (success) in
				if success {
					effort.managedObjectContext!.saveContext()
					self?.setProfilesForEffort(effort)
				}
			})
		}
	}
	
	private func setProfilesForEffort(_ effort : RVEffort) {
		speedProfileController.setPrimaryProfile(streamOwner: effort, profileType: .speed)
		powerProfileController.setPrimaryProfile(streamOwner: effort, profileType: .power)
		HRProfileController.setPrimaryProfile(streamOwner: effort, profileType: .heartRate)

		if shortestElapsed != nil && shortestElapsed! != effort {
			speedProfileController.addSecondaryProfile(owner: shortestElapsed!, profileType: .speed)
			powerProfileController.addSecondaryProfile(owner: shortestElapsed!, profileType: .power)
			HRProfileController.addSecondaryProfile(owner: shortestElapsed!, profileType: .heartRate)
		}
	}

}



