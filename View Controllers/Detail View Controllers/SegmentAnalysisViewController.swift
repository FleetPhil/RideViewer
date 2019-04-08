//
//  SegmentAnalysisViewController.swift
//  RideViewer
//
//  Created by Home on 10/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class SegmentAnalysisViewController: UIViewController, RVEffortTableDelegate, RVRouteProfileScrollViewDelegate {
	
	@IBOutlet weak var topInfoLabel: UILabel!
	@IBOutlet weak var bottomInfoLabel: UILabel!
	
	@IBOutlet weak var topContainerView: UIView!
	@IBOutlet weak var midContainerView: UIView!
	@IBOutlet weak var bottomContainerView: UIView!
	
	
	private var effortTableViewController : RVEffortListViewController!
	private var speedProfileController : RVRouteProfileViewController!
	private var powerProfileController : RVRouteProfileViewController!
	private var HRProfileController : RVRouteProfileViewController!

    var profileControllers : [RVRouteProfileViewController] {
        return [speedProfileController, powerProfileController, HRProfileController]
    }
    
	// Model
	var segment : RVSegment! {
		didSet {
			shortestElapsed = segment.shortestElapsedEffort()
		}
	}
	var highlightEffort : RVEffort? = nil
	
	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	private var effortFilters : [EffortFilter] = []
	private var effortSort : EffortSort = .elapsedTime
	private var popupController : UIViewController?
	
	// MARK: Properties
	private var shortestElapsed : RVEffort?
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.title = segment.name! + " (" + segment.distance.distanceDisplayString + ")"

		guard let shortest = shortestElapsed else {
			appLog.error("No shortest effort for analysis")
			return
		}
        
        speedProfileController.delegate = self
        powerProfileController.delegate = self
        HRProfileController.delegate = self

		topInfoLabel.text = EmojiConstants.Fastest + " " + shortest.activity.name
		topInfoLabel.textColor = ViewProfileDisplayType.primary.displayColour
		bottomInfoLabel.attributedText = shortest.effortDisplayText
		
		// Get stream data for the fastest ride on this segment and set as the primary
		displayStreamsForEffort(shortest, displayType: .primary)
		
		if highlightEffort != nil {
			displayStreamsForEffort(highlightEffort!, displayType: .secondary)
			// Select this effort in the table and scroll to it
			effortTableViewController.highlightEffort(highlightEffort!)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVRouteProfileViewController {
			switch segue.identifier {
			case "SpeedProfileSegue":	speedProfileController = destination
			case "HRProfileSegue":		HRProfileController = destination
			case "PowerProfileSegue":	powerProfileController = destination
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
		speedProfileController.removeSecondaryProfiles()
		powerProfileController.removeSecondaryProfiles()
		HRProfileController.removeSecondaryProfiles()
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
			if speedProfileController.setPrimaryProfile(streamOwner: effort, profileType: .speed) {
				speedProfileController.addProfile(owner: effort.segment, profileType: .altitude , displayType: .background)
			}
			if HRProfileController.setPrimaryProfile(streamOwner: effort, profileType: .heartRate) {
				HRProfileController.addProfile(owner: effort.segment, profileType: .altitude , displayType: .background)
			} else {
				appLog.debug("No HR for \(effort.activity.name)")
				midContainerView.isHidden = true
			}
			if powerProfileController.setPrimaryProfile(streamOwner: effort, profileType: .power) {
				powerProfileController.addProfile(owner: effort.segment, profileType: .altitude , displayType: .background)
			} else {
				appLog.debug("No power for \(effort.activity.name)")
				bottomContainerView.isHidden = true
			}
		case .secondary:
			// Will not add if primary does not exist for this data type
			speedProfileController.addProfile(owner: effort, profileType: .speed, displayType: .secondary)
			powerProfileController.addProfile(owner: effort, profileType: .power, displayType: .secondary)
			HRProfileController.addProfile(owner: effort, profileType: .heartRate, displayType: .secondary)
		default:
			appLog.error("Unexpected display type \(displayType) requested")
			break
		}
	}
    
    // MARK: Profile controller delegate
    
    func didChangeScale(viewController: UIViewController, newScale: CGFloat, withOffset: CGPoint) {
    }
    
    func didEndScrolling(viewController: UIViewController, newOffset: CGPoint) {
    }
    
    func didScroll(viewController: UIViewController, newOffset: CGPoint) {
   	}
    

}



