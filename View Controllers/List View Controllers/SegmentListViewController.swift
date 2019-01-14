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

fileprivate enum SegmentSort : String, PopupSelectable, CaseIterable {
	case distance = "distance"
	case grade = "averageGrade"
	
	var displayString : String {           // Text to use when choosing item
		switch self {
		case .distance:		return "Distance"
		case .grade:		return "Av. Grade"
		}
	}
}

class SegmentListViewController: ListViewMaster, UITableViewDelegate {
	
	// MARK: Model
	private lazy var dataManager = DataManager<RVSegment>()
	private var sortKey : SegmentSort = .distance
	
	@IBOutlet weak var sortButton: UIBarButtonItem!
	
	// MARK: Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "Segments"
		tableView.dataSource    = dataManager
		tableView.delegate      = self
		tableView.rowHeight = UITableView.automaticDimension
		
		dataManager.delegate = self
		
		setDataManager()
	}
	
	func setDataManager() {
		let predicate = Settings.sharedInstance.segmentSettingsPredicate
		let sortDescriptor = NSSortDescriptor(key: sortKey.rawValue, ascending: false)
		_ = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: predicate)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "SegmentListToSegmentDetail", sender: self)
	}

	@IBAction func sortButtonPressed(_ sender: Any) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<SegmentSort>()
		chooser.title = "Select sort order"
		chooser.showSelectionPopup(items: SegmentSort.allCases,
								   sourceView: tableView,
								   updateHandler: newSortOrder)
	}
	
	private func newSortOrder(newOrder : [SegmentSort]) {
		if let newSort = newOrder.first {
			sortKey = newSort
			setDataManager()
			tableView.reloadData()
		}
	}

	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination.activeController as? SegmentDetailViewController {
			destination.segment = dataManager.objectAtIndexPath(tableView.indexPathForSelectedRow!)
		}
	}
	
}
