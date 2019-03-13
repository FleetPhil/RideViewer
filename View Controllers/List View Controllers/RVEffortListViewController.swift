//
//  RVEffortTableViewController.swift
//  RideViewer
//
//  Created by Home on 11/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData

protocol RVEffortTableDelegate : class {
	func didSelectEffort(effort : RVEffort)
	func didDeselectEffort(effort : RVEffort)
}

class RVEffortListViewController: UIViewController, UITableViewDelegate {
	
	// Public interface
	// Type of object - segment or activity - determines the data to be shown
	var ride : NSManagedObject!
	weak var delegate : RVEffortTableDelegate?

	// Outlet
	@IBOutlet weak var tableView: RVSortFilterTableView!

	// Private properties
	private var effortTableViewType : EffortTableViewType = .effortsForActivity
	private lazy var dataManager = DataManager<RVEffort>()
	private var effortSortKey : EffortSort = .elapsedTime
	private var effortFilters : [EffortFilter] = EffortFilter.allCases
	
	private var popupController : UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

		switch ride {
		case is RVActivity:
			effortTableViewType = .effortsForActivity
		case is RVSegment:
			effortTableViewType = .effortsForSegment
		default:
			appLog.error("Unsupported ride type for effort table")
		}

		tableView.delegate		= self
		tableView.dataSource    = dataManager
		tableView.rowHeight 	= UITableView.automaticDimension
		tableView.tag 			= effortTableViewType.rawValue
		
		dataManager.tableView = tableView
		
		setDataManager()
		tableView.reloadData()
	}
	
	func setDataManager() {
		dataManager.sortDescriptor = NSSortDescriptor(key: effortSortKey.rawValue, ascending: self.effortSortKey.defaultAscending)
		switch effortTableViewType {
		case .effortsForActivity:
			let activityPredicate = NSPredicate(format: "activity.id == %@", argumentArray: [(ride as! RVActivity).id])
			dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [EffortFilter.predicateForFilters(self.effortFilters), activityPredicate])
		case .effortsForSegment:
			let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
			let segmentPredicate = NSPredicate(format: "segment.id == %@", argumentArray: [(ride as! RVSegment).id])
			let effortPredicate = EffortFilter.predicateForFilters(self.effortFilters)
			dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [settingsPredicate, segmentPredicate, effortPredicate])
		}
		_ = dataManager.fetchObjects()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let effort = dataManager.objectAtIndexPath(indexPath) {
			delegate?.didSelectEffort(effort: effort)
		}
	}
	
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		if let effort = dataManager.objectAtIndexPath(indexPath) {
			delegate?.didDeselectEffort(effort: effort)
		}
	}
	
	@objc func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<EffortSort>()
		chooser.title = "Sort order"
		popupController	= chooser.showSelectionPopup(items: EffortSort.sortOptionsForActivity, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	@objc func filterButtonPressed(sender: UIView) {
		let chooser = PopupupChooser<EffortFilter>()
		chooser.title = "Include"
		chooser.multipleSelection = true
		chooser.selectedItems = self.effortFilters		// self.filters
		popupController = chooser.showSelectionPopup(items: EffortFilter.allCases, sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	private func newFilters(_ newFilters : [EffortFilter]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		if let selectedFilters = newFilters {
			self.effortFilters = selectedFilters
			setDataManager()
			tableView.reloadData()
		}
	}
	
	private func newSortOrder(newOrder : [EffortSort]?) {
		popupController?.dismiss(animated: true, completion: nil)
		if let newSort = newOrder?.first {
			self.effortSortKey = newSort
			setDataManager()
			tableView.reloadData()
		}
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView()
		headerView.backgroundColor = UIColor.lightGray
		return headerView
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let header = RVSortFilterHeaderView(frame: view.bounds)
		header.sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
		header.filterButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
		header.headerLabel.text = "\(tableView.numberOfRows(inSection: 0))"
		view.addSubview(header)
	}

}
