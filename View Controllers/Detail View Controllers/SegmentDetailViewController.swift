//
//  SegmentDetailViewController.swift
//  RideViewer
//
//  Created by Home on 05/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData

class SegmentDetailViewController: UIViewController {
	
	//MARK: Model
	var segment : RVSegment!

	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	
	@IBOutlet weak var tableView: RVTableView!
	
	@IBOutlet weak var effortsLabel: UILabel!
	
	@IBOutlet weak var mapView: RideMapView! {
		didSet {
			mapView.mapType = .standard
			mapView.delegate = mapView
		}
	}
	
	@IBOutlet weak var routeElevationView: RVRouteElevationView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.sortFilterDelegate = self
		
		if segment != nil {
			updateView()
		}
	}
	
	func updateView() {
		self.title 				= segment.name
		
		self.effortsLabel.text	= "\(tableView.numberOfRows(inSection: 0)) Efforts"
		self.effortsLabel.textColor = segment.resourceState.resourceStateColour
		
		mapView!.addRoute(segment,highlighted: true)

		if segment.resourceState != .detailed {
            // Get segment details including route
            tableView.startDataRetrieval()
			StravaManager.sharedInstance.updateSegment(segment, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
				guard self != nil else { return }
				if success {
					self!.mapView!.addRoute(self!.segment, highlighted: true)
                    // Get all efforts for this segment
                    StravaManager.sharedInstance.effortsForSegment(self!.segment, page: 1, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [ weak self ] success in
                        self?.tableView?.endDataRetrieval()
                        self?.effortsLabel.text    = "\(self?.tableView.numberOfRows(inSection: 0) ?? 0) Efforts"
                    })
				} else {		// Get segment details failed
					self!.tableView.dataRetrievalFailed()
				}
			})
		}
		setupEfforts(segment)
		
	}
}

extension SegmentDetailViewController : SortFilterDelegate {
	// MARK: effort table view support
	
	func setupEfforts(_ forSegment : RVSegment) {
		tableView.dataSource    = dataManager
		tableView.rowHeight 	= UITableView.automaticDimension
		
		tableView.tag = EffortTableViewType.effortsForSegment.rawValue
		dataManager.tableView = tableView
		setDataManager(sortKey: .movingTime, ascending: EffortSort.movingTime.defaultAscending)
	}
	
    func setDataManager(sortKey : EffortSort, ascending :  Bool) {
		let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
		let sortDescriptor = NSSortDescriptor(key: sortKey.rawValue, ascending: ascending)
		let filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "segment.id == %@", argumentArray: [segment.id]), settingsPredicate])
		let efforts = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: filterPredicate)
		self.effortsLabel.text = "\(efforts.count) Efforts"
	}
	
	func tableRowDeselectedAtIndex(_ index: IndexPath) {
		let activity = dataManager.objectAtIndexPath(index)!.activity
		self.mapView.removeRoute(activity)
	}
	
	func tableRowSelectedAtIndex(_ index: IndexPath) {
		let effort = dataManager.objectAtIndexPath(index)!
		self.mapView.addRoute(effort.activity, highlighted: false)
		
		routeElevationView.drawForActivity(effort.activity, streamType: .altitude, effort: effort)		// Will draw blank if no streams for this activity
		if effort.activity.streams.count == 0 {
			// Get streams
			StravaManager.sharedInstance.streamsForActivity(effort.activity, context: effort.managedObjectContext!, completionHandler: { [ weak self] success in
				if success {
					self?.routeElevationView.drawForActivity(effort.activity, streamType: .altitude, effort: effort)
				} else {
					appLog.debug("Failed to get stream data for activity \(effort.activity) ")
				}
			})
		}
		
//		performSegue(withIdentifier: "SegmentEffortListToSegmentDetail", sender: self)
	}
	
	func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<EffortSort>()
		chooser.title = "Select sort order"
		chooser.showSelectionPopup(items: EffortSort.allCases,
								   sourceView: sender,
								   updateHandler: newSortOrder)
	}
	
	func filterButtonPressed(sender: UIView) {
		
	}
	
	private func newSortOrder(newOrder : [EffortSort]) {
		if let newSort = newOrder.first {
			setDataManager(sortKey: newSort, ascending: newSort.defaultAscending)
			tableView.reloadData()
		}
	}

	
	
}

