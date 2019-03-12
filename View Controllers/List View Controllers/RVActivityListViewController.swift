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

class RVActivityListViewController: UIViewController, UITableViewDelegate {

	// MARK: Model
	private lazy var dataManager = DataManager<RVActivity>()
	
	// Outlets
	@IBOutlet weak var tableView: RVSortFilterTableView!
	var tableDataIsComplete = true

	// Properties
	private var filters : [ActivityFilter]!
	private var sortKey : ActivitySort!
	private var popupController : UIViewController?

	// MARK: Lifecycle
	override func viewDidLoad() {
        super.viewDidLoad()

		self.title = "Activities"
		
		// Set table view parameters
		tableView.dataSource    = dataManager
		tableView.delegate		= self
		
//		NotificationCenter.default.addObserver(self, selector: #selector(settingsChanged), name: .didChangeActivitySettings, object: nil)

		// Setup the data source
		dataManager.tableView = self.tableView
		self.filters = [.cycleRide, .longRide]
		self.sortKey = .date
        setDataManager()

		if let activities : [RVActivity] = CoreDataManager.sharedManager().viewContext.fetchObjects() {
			if let lastActivityDate = activities.map({ $0.startDate as Date }).max() {
				appLog.debug("Last activity at \(lastActivityDate) (\(Int(lastActivityDate.timeIntervalSince1970)))")
			} else {
				appLog.debug("No activities stored")
			}
		}
	}
	
	@IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
		self.presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
    func setDataManager() {
		guard sortKey != nil, filters != nil else { return }
		dataManager.filterPredicate = ActivityFilter.predicateForFilters(self.filters)
		dataManager.sortDescriptor = NSSortDescriptor(key: self.sortKey.rawValue, ascending: self.sortKey.defaultAscending)
		_ = dataManager.fetchObjects()
	}

	// MARK: Settings changed
//	@objc func settingsChanged(_ notification : Notification) {
//		setDataManager(sortKey: .date, ascending: ActivitySort.date.defaultAscending)
//	}
	
	// MARK: Sort and filter
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView()
		headerView.backgroundColor = UIColor.lightGray
		return headerView
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let sectionHeaderView = RVSortFilterHeaderView(frame: view.bounds)
		sectionHeaderView.sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
		sectionHeaderView.filterButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
		sectionHeaderView.headerLabel.text = "Header"
		view.addSubview(sectionHeaderView)
	}
	
	@objc func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<ActivitySort>()
		chooser.title = "Select sort order"
		popupController = chooser.showSelectionPopup(items: ActivitySort.allCases, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	@objc func filterButtonPressed(sender: UIView) {
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

