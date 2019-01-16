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
	
	// MARK: Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "Segments"
		tableView.dataSource    = dataManager
		tableView.rowHeight = UITableView.automaticDimension
		
		tableView.sortFilterDelegate = self
		
		dataManager.tableView = self.tableView
		
		setDataManager(sortKey: .distance, ascending: SegmentSort.distance.defaultAscending)
	}
	
    func setDataManager(sortKey : SegmentSort, ascending : Bool) {
		let predicate = Settings.sharedInstance.segmentSettingsPredicate
		let sortDescriptor = NSSortDescriptor(key: sortKey.rawValue, ascending: ascending)
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
		
	}
	
	private func newSortOrder(newOrder : [SegmentSort]) {
		if let newSort = newOrder.first {
			setDataManager(sortKey: newSort, ascending: newSort.defaultAscending)
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
