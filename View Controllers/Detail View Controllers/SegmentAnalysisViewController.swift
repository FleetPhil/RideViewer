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
	
	private var routeProfileController : RVRouteProfileViewController!
	private var effortTableViewController : RVEffortTableViewController!
	
	// Model
	var segment : RVSegment!
	
	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	private var effortFilters : [EffortFilter] = []
	private var effortSort : EffortSort = .elapsedTime
	private var popupController : UIViewController?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.title = segment.name!
		topInfoLabel.text = "\(segment.efforts.count) efforts"
		
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVRouteProfileViewController {
			routeProfileController = destination
		}
		if let destination = segue.destination as? RVEffortTableViewController {
			effortTableViewController = destination
			effortTableViewController.delegate = self
			effortTableViewController.ride = segment
		}
	}
	
	// MARK: Effort table delegate
	func didSelectEffort(effort: RVEffort) {
		appLog.debug("Selected \(effort.activity.name)")
	}
	
	func didDeselectEffort(effort: RVEffort) {
		appLog.debug("Des75zaelected \(effort.activity.name)")
	}
}



