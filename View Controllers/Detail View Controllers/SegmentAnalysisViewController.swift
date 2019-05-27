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
	
	@IBOutlet weak var scrollingProfileView: ScrollingPageView!
	
	@IBOutlet weak var profileInfoLabel: UILabel!
	
	private var topViewDataType : RVStreamDataType = .speed
	private var midViewDataType : RVStreamDataType = .heartRate
	private var bottomViewDataType : RVStreamDataType = .gearRatio
	
	private var effortTableViewController : RVEffortListViewController!
	private var topProfileController : RVRouteProfileViewController!
	private var midProfileController : RVRouteProfileViewController!
	private var bottomProfileController : RVRouteProfileViewController!

    var profileControllers : [RVRouteProfileViewController] {
        return [topProfileController, midProfileController, bottomProfileController]
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
		
		// Instantiate the profile controllers
		topProfileController = storyboard!.instantiateViewController(withIdentifier: "RVRouteProfileviewController") as? RVRouteProfileViewController
		midProfileController = storyboard!.instantiateViewController(withIdentifier: "RVRouteProfileviewController") as? RVRouteProfileViewController
		bottomProfileController = storyboard!.instantiateViewController(withIdentifier: "RVRouteProfileviewController") as? RVRouteProfileViewController

		scrollingProfileView.addScrollingView(topProfileController.view, ofType: topViewDataType, horizontal: false)
		scrollingProfileView.addScrollingView(midProfileController.view, ofType: midViewDataType, horizontal: false)
		scrollingProfileView.addScrollingView(bottomProfileController.view, ofType: bottomViewDataType, horizontal: false)
		
		scrollingProfileView.viewChangedCallback = setInfoForPage(_:)

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
		
		// Set the display for the first page
		setInfoForPage(0)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVEffortListViewController {
			effortTableViewController = destination
			effortTableViewController.delegate = self
			effortTableViewController.ride = segment
		}
	}
	
	// MARK: Set description for the active profile view
	func setInfoForPage(_ page : Int) {
		if let viewType = scrollingProfileView.viewTypeForPage(page), let dataType = viewType as? RVStreamDataType {
			profileInfoLabel.text = dataType.stringValue
		}
	}
	
	// MARK: Effort table delegate
	func didSelectEffort(effort: RVEffort) {
		displayStreamsForEffort(effort, displayType: .secondary)
	}
	
	func didDeselectEffort(effort: RVEffort) {
		topProfileController.removeSecondaryProfiles()
		midProfileController.removeSecondaryProfiles()
		bottomProfileController.removeSecondaryProfiles()
	}
	
	// MARK: Effort profile setup
    // TODO: change to new 'streams' method
	private func displayStreamsForEffort(_ effort: RVEffort, displayType: ViewProfileDisplayType) {
        appLog.debug("Segment is \(effort.segment.name!)")
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
            appLog.debug("Top profile is \(topViewDataType)")
            topProfileController.setPrimaryProfile(streamOwner: effort, profileType: topViewDataType, seriesType: .distance)
            topProfileController.addProfile(streamOwner: effort.segment, profileType: .altitude , displayType: .background, withRange: nil)

//            midProfileController.setPrimaryProfile(streamOwner: effort, profileType: midViewDataType)
//            midProfileController.addProfile(streamOwner: effort.segment, profileType: .altitude , displayType: .background, withRange: nil)
//
//            bottomProfileController.setPrimaryProfile(streamOwner: effort, profileType: bottomViewDataType)
//            bottomProfileController.addProfile(streamOwner: effort.segment, profileType: .altitude , displayType: .background, withRange: nil)

        case .secondary:
            // Will not add if primary does not exist for this data type
            topProfileController.addProfile(streamOwner: effort, profileType: topViewDataType, displayType: .secondary, withRange: nil)
//            midProfileController.addProfile(streamOwner: effort, profileType: midViewDataType, displayType: .secondary, withRange: nil)
//            bottomProfileController.addProfile(streamOwner: effort, profileType: bottomViewDataType, displayType: .secondary, withRange: nil)
            
        default:
            appLog.error("Unexpected display type \(displayType) requested")
            break
        }
	}
}



