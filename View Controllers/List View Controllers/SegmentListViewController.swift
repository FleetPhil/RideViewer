//
//  SegmentListViewController.swift
//  RideViewer
//
//  Created by Home on 29/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import StravaSwift
import CoreData

class SegmentListViewController: UIViewController, SortFilterDelegate {
	
	// MARK: Model
	private lazy var dataManager = DataManager<RVSegment>()
	
	@IBOutlet weak var tableView: RVTableView!
	
	@IBOutlet weak var sortButton: UIBarButtonItem!
	
	// Properties
	var filters : [SegmentFilter]!
	var sortKey : SegmentSort!
	var sortOrderAscending : Bool!
	
	// MARK: Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "Segments"
		tableView.dataSource    = dataManager
		tableView.rowHeight = UITableView.automaticDimension
		
		tableView.sortFilterDelegate = self
		
		dataManager.tableView = self.tableView
		
		self.filters = [.long, .flat, .ascending, .descending, .multipleEfforts]
		self.sortKey = .distance
		self.sortOrderAscending = false
		
		setDataManager()
	}
	
    func setDataManager() {
		guard sortKey != nil, filters != nil else { return }
		let predicate = SegmentFilter.predicateForFilters(filters)
		let sortDescriptor = NSSortDescriptor(key: sortKey.rawValue, ascending: sortOrderAscending)
		_ = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: predicate)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "SegmentListToSegmentDetail", sender: self)
	}

	func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<SegmentSort>()
		chooser.title = "Select sort order"
		chooser.showSelectionPopup(items: SegmentSort.allCases,
								   sourceView: sender,
								   updateHandler: newSortOrder)
	}
	
	func filterButtonPressed(sender: UIView) {
		let chooser = PopupupChooser<SegmentFilter>()
		chooser.title = "Include"
		chooser.multipleSelection = true
		chooser.selectedItems = self.filters
		chooser.showSelectionPopup(items: SegmentFilter.allCases, sourceView: sender, updateHandler: newFilters)
	}
	
	private func newFilters(_ newFilters : [SegmentFilter])  {
		self.filters = newFilters
		setDataManager()
		tableView.reloadData()
	}
	
	private func newSortOrder(newOrder : [SegmentSort]) {
		if let newSort = newOrder.first {
			self.sortKey = newSort
			self.sortOrderAscending = self.sortKey.defaultAscending
			setDataManager()
			tableView.reloadData()
		}
	}
	
	func tableRowSelectedAtIndex(_ index: IndexPath) {
		performSegue(withIdentifier: "SegmentListToSegmentDetail", sender: self)
	}

	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination.activeController as? SegmentDetailViewController {
			destination.segment = dataManager.objectAtIndexPath(tableView.indexPathForSelectedRow!)
		}
	}
	
}
