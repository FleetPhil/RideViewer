//
//  ActivityListViewController.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import StravaSwift
import CoreData


class ActivityListViewController: UIViewController, SortFilterDelegate {

	// MARK: Model
	private lazy var dataManager = DataManager<RVActivity>()
	
	// Outlets
	@IBOutlet weak var tableView: RVTableView!
	var tableDataIsComplete = true

	// Properties
	private var filters : [ActivityFilter]!
	private var sortKey : ActivitySort!
	private var sortOrderAscending : Bool!
	private var popupController : UIViewController?

	// MARK: Lifecycle
	override func viewDidLoad() {
        super.viewDidLoad()

		self.title = "Activities"
		tableView.dataSource    = dataManager
		tableView.rowHeight = UITableView.automaticDimension
		
		tableView.sortFilterDelegate = self
		
//		NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .didChangeActivitySettings, object: nil)
		dataManager.tableView = self.tableView
		
		self.filters = [.cycleRide, .longRide]
		self.sortKey = .date
		self.sortOrderAscending = false
        setDataManager()

		if let activities : [RVActivity] = CoreDataManager.sharedManager().viewContext.fetchObjects() {
			if let lastActivityDate = activities.map({ $0.startDate as Date }).max() {
				appLog.debug("Last activity at \(lastActivityDate) (\(Int(lastActivityDate.timeIntervalSince1970)))")
			} else {
				appLog.debug("No activities stored")
			}
		}
	}
	
//	override func viewWillAppear(_ animated: Bool) {
//		// Select the first row if no selected row and activate the detail view
//		performSegue(withIdentifier: "ActivityListToActivityDetail", sender: self)
//	}
	
	@IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
		self.presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
    func setDataManager() {
		guard sortKey != nil, filters != nil else { return }
		dataManager.filterPredicate = ActivityFilter.predicateForFilters(self.filters)
		dataManager.sortDescriptor = NSSortDescriptor(key: self.sortKey.rawValue, ascending: self.sortOrderAscending)
		_ = dataManager.fetchObjects()
	}
	
	func predicateForFilters(_ filters : [ActivityFilter]) -> NSCompoundPredicate {
		var predicate = NSCompoundPredicate()
		let filterGroups = Dictionary(grouping: filters, by: { $0.filterGroup })
		for group in filterGroups {
			let groupPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: group.value.map({ $0.predicateForFilterOption() } ))
			predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, groupPredicate])
		}
		return predicate
	}

	// MARK: Settings changed
//	@objc func settingsChanged(_ notification : Notification) {
//		setDataManager(sortKey: .date, ascending: ActivitySort.date.defaultAscending)
//	}
	
	func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<ActivitySort>()
		chooser.title = "Select sort order"
		popupController = chooser.showSelectionPopup(items: ActivitySort.allCases, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	func filterButtonPressed(sender: UIView) {
		let chooser = PopupupChooser<ActivityFilter>()
		chooser.title = "Include"
		chooser.multipleSelection = true
		chooser.selectedItems = self.filters
		popupController = chooser.showSelectionPopup(items: ActivityFilter.allCases, sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	private func newSortOrder(newOrder : [ActivitySort]?) {
		popupController?.dismiss(animated: true, completion: nil)
		if let newSort = newOrder?.first {
			self.sortKey = newSort
			self.sortOrderAscending = newSort.defaultAscending
			setDataManager()
			tableView.reloadData()
		}
	}
	
	private func newFilters(_ newFilters : [ActivityFilter]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		if let returnedFilters = newFilters {			// nil means cancelled
			self.filters = returnedFilters
			setDataManager()
			tableView.reloadData()
		}
	}
	
	func tableRowSelectedAtIndex(_ index: IndexPath) {
		performSegue(withIdentifier: "ActivityListToActivityDetail", sender: self)
	}
    
    func didScrollToVisiblePaths(_ paths : [IndexPath]?) {
        
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination.activeController as? ActivityDetailViewController {
			if let path = tableView.indexPathForSelectedRow {
				destination.activity = dataManager.objectAtIndexPath(path)
			} else {
				destination.activity = nil
			}
		}
    }
}


extension UIViewController {
	var activeController : UIViewController? {
		if let controller = self as? UINavigationController {
			return controller.topViewController
		} else {
			return self
		}
	}
	
	var detailViewController : UIViewController? {
		return self.splitViewController?.viewControllers.last?.activeController
	}
	
}

