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
		
		mapView!.showForRoute(segment)
		
		if segment.resourceState != .detailed {
            // Get segment details including route
            tableView.startDataRetrieval()
			StravaManager.sharedInstance.updateSegment(segment, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] in
				if let currentSelf = self {
					currentSelf.mapView!.showForRoute(currentSelf.segment)
                    // Get all efforts for this segment
                    StravaManager.sharedInstance.effortsForSegment(currentSelf.segment, page: 1, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [ weak self ] in
                        self?.tableView?.endDataRetrieval()
                        self?.effortsLabel.text    = "\(self?.tableView.numberOfRows(inSection: 0) ?? 0) Efforts"
                    })
				}
			})
		}
		setupEfforts(segment)
	}
	
	
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SegmentDetailViewController : SortFilterDelegate {
	// MARK: effort table view support
	
	func setupEfforts(_ forSegment : RVSegment) {
		tableView.dataSource    = dataManager
		tableView.rowHeight 	= UITableView.automaticDimension
		
		tableView.tag = EffortTableViewType.effortsForSegment.rawValue
		dataManager.tableView = tableView
		setDataManager(sortKey: .distance, ascending: EffortSort.distance.defaultAscending)
	}
	
    func setDataManager(sortKey : EffortSort, ascending :  Bool) {
		let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
		let sortDescriptor = NSSortDescriptor(key: sortKey.rawValue, ascending: ascending)
		let filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "segment.id == %@", argumentArray: [segment.id]), settingsPredicate])
		let efforts = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: filterPredicate)
		self.effortsLabel.text = "\(efforts.count) Efforts"
	}
	
	func tableRowSelectedAtIndex(_ index: IndexPath) {
		performSegue(withIdentifier: "SegmentEffortListToSegmentDetail", sender: self)
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

