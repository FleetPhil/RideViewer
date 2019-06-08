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
	// Type of object - segment or activity - determines the data to be shown, or nil for all efforts
	var ride : NSManagedObject?
	weak var delegate : RVEffortTableDelegate?

	// Outlet
	@IBOutlet weak var tableView: RVSortFilterTableView!

	// Private properties
	private var effortTableViewType : EffortTableViewType = .effortsForActivity
	private(set) lazy var dataManager = DataManager<RVEffort>()
	private var effortSortKey : EffortSort!
	private var filters : [EffortFilter] = EffortFilter.allCases
	
	private var popupController : UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
		switch ride {
		case .some(is RVActivity):
			effortTableViewType = .effortsForActivity
			effortSortKey		= .sequence
		case .some(is RVSegment):
			effortTableViewType = .effortsForSegment
			effortSortKey		= .elapsedTime
        case .none:
            effortTableViewType = .allEfforts
            effortSortKey       = .elapsedTime
		default:
			appLog.error("Unsupported ride type for effort table")
		}

		tableView.delegate		= self
		tableView.dataSource    = dataManager
		tableView.rowHeight 	= UITableView.automaticDimension
		tableView.tag 			= effortTableViewType.rawValue
        
        self.filters = savedFilters()
		
		dataManager.tableView = tableView
		setDataManager()
		
		tableView.reloadData()
	}
	
	// Public interface
	func highlightEffort(_ effort : RVEffort?) {
		guard let effort = effort else {
			// No effort to highlight
			return
		}
		if let indexPath = dataManager.indexPathForObject(effort) {
			tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
		} else {
			appLog.error("Unable to find selected effort in table")
		}
	}
	
	// Private functions
	private func setDataManager() {
		dataManager.sortDescriptor = NSSortDescriptor(key: effortSortKey.rawValue, ascending: self.effortSortKey.defaultAscending)
		switch effortTableViewType {
		case .effortsForActivity:
			let activityPredicate = NSPredicate(format: "activity.id == %@", argumentArray: [(ride as! RVActivity).id])
			dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [EffortFilter.predicateForFilters(self.filters), activityPredicate])
		case .effortsForSegment:
			let segmentPredicate = NSPredicate(format: "segment.id == %@", argumentArray: [(ride as! RVSegment).id])
			let effortPredicate = EffortFilter.predicateForFilters(self.filters)
			dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [segmentPredicate, effortPredicate])
        case .allEfforts:
            dataManager.filterPredicate = EffortFilter.predicateForFilters(self.filters)
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
	
	@objc private func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
        let chooser = PopupupChooser<EffortSort>(title: "Sort order")
		popupController	= chooser.showSelectionPopup(items: EffortSort.sortOptionsForActivity, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	@objc private func filterButtonPressed(sender: UIView) {
        let chooser = PopupupChooser<EffortFilter>(title: "Include")
		chooser.multipleSelection = true
		chooser.selectedItems = self.filters
		popupController = chooser.showSelectionPopup(items: EffortFilter.allCases, sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	private func newFilters(_ newFilters : [EffortFilter]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		if let selectedFilters = newFilters {
			self.filters = selectedFilters
            saveFilters()
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
    
    private func saveFilters() {
        UserDefaults.standard.set(self.filters.map({ $0.rawValue } ), forKey: "EffortFilters")
    }
    
    private func savedFilters()->[EffortFilter] {
        if let rawFilters = UserDefaults.standard.array(forKey: "EffortFilters") as? [String] {
            let filters = rawFilters.compactMap({ EffortFilter(rawValue: $0) })
            return filters
        }
        return EffortFilter.allCases
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
