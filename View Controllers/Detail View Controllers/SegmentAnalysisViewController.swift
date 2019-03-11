//
//  SegmentAnalysisViewController.swift
//  RideViewer
//
//  Created by Home on 10/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class SegmentAnalysisViewController: UIViewController {
	
	@IBOutlet weak var topInfoLabel: UILabel!
	@IBOutlet weak var bottomInfoLabel: UILabel!
	
	@IBOutlet weak var effortTableView: RVTableView!
	
	private var routeProfileController : RVRouteProfileViewController!
	
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
		
		setupEfforts(segment)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVRouteProfileViewController {
			routeProfileController = destination
		}
	}
}

extension SegmentAnalysisViewController : SortFilterDelegate {
	
	// Placeholder
	var tableDataIsComplete: Bool {
		return true
	}
	
	// MARK: effort table view support
	
	func setupEfforts(_ forSegment : RVSegment) {
		effortTableView.dataSource    = dataManager
		effortTableView.rowHeight 	= UITableView.automaticDimension
		
		effortTableView.tag = EffortTableViewType.effortsForSegment.rawValue
		dataManager.tableView = effortTableView
		setDataManager()
	}
	
	func setDataManager() {
		dataManager.sortDescriptor = NSSortDescriptor(key: effortSort.rawValue, ascending: effortSort.defaultAscending)
		
		let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
		let segmentPredicate = NSPredicate(format: "segment.id == %@", argumentArray: [segment.id])
		let effortPredicate = EffortFilter.predicateForFilters(self.effortFilters)
		dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [settingsPredicate, segmentPredicate, effortPredicate])
		let _ = dataManager.fetchObjects()
	}
	
	func tableRowDeselectedAtIndex(_ index: IndexPath) {
		let activity = dataManager.objectAtIndexPath(index)!.activity
	}
	
	func tableRowSelectedAtIndex(_ index: IndexPath) {
		let effort = dataManager.objectAtIndexPath(index)!
	}
	
	func didScrollToVisiblePaths(_ paths : [IndexPath]?) {
		
	}
	
	func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<EffortSort>()
		chooser.title = "Select sort order"
		popupController = chooser.showSelectionPopup(items: EffortSort.sortOptionsForSegment, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	func filterButtonPressed(sender: UIView) {
		let chooser = PopupupChooser<EffortFilter>()
		chooser.title = "Include"
		chooser.multipleSelection = true
		chooser.selectedItems = self.effortFilters
		popupController = chooser.showSelectionPopup(items: [], sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	private func newSortOrder(newOrder : [EffortSort]?) {
		popupController?.dismiss(animated: true, completion: nil)
		if let newSort = newOrder?.first {
			self.effortSort = newSort
			setDataManager()
			effortTableView.reloadData()
		}
	}
	
	private func newFilters(_ newFilters : [EffortFilter]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		if let selectedFilters = newFilters {
			self.effortFilters = selectedFilters
			setDataManager()
			effortTableView.reloadData()
		}
	}
	
	
	
}


