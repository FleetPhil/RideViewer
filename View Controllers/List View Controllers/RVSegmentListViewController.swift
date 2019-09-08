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

class RVSegmentListViewController: UIViewController, UITableViewDelegate {
	
	// MARK: Model
	private lazy var dataManager = DataManager<RVSegment>()
	
	@IBOutlet weak var tableView: RVSortFilterTableView!
	var tableDataIsComplete = false
	
	// Properties
    private var filters : [SegmentFilter]!    // TODO: should retrieve not reset
    private var sortKey : SegmentSort!
	private var popupController : UIViewController?
	
	// MARK: Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "Segments"
		
		// Set table view parameters
		tableView.dataSource    = dataManager
		tableView.delegate		= self
		
		// Setup the data source
		dataManager.tableView = self.tableView
		
//		self.filters = savedFilters()
		setDataManager()
	}
	
    func setDataManager() {
        guard sortKey != nil, filters != nil else { return }
        dataManager.filterPredicate = SegmentFilter.predicateForFilters(self.filters)
        dataManager.sortDescriptor = NSSortDescriptor(key: self.sortKey.rawValue, ascending: self.sortKey.defaultAscending)
        _ = dataManager.fetchObjects()
	}
	
	@IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
		self.presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
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
        let picker = StringPicker(title: "Sort", choices: SegmentSort.allCases.map({ $0.selectionLabel }))
            .setDoneButtonAction({ _, rowIndex, selectedString in
                self.sortKey = SegmentSort.allCases[rowIndex]
                self.setDataManager()
                self.tableView.reloadData()
            })
        picker.appear(originView: sender, baseViewController: self)
	}
	
	@objc func filterButtonPressed(sender: UIView) {
        let chooser = PopupupChooser(title: "Include")
        popupController = chooser.selectionPopup(items: RVSegment.filterParams, multipleSelection: true, sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	private func newFilters(_ newFilters : [PopupItem]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		
//        if let returnedFilters = newFilters {        // Will be nil if cancelled
//            self.filters = returnedFilters
//            saveFilters()
//            setDataManager()
//            tableView.reloadData()
//        }
	}
	
	private func newSortOrder(newOrder : [PopupItem]?) {
		popupController?.dismiss(animated: true, completion: nil)
//        if let newSort = newOrder?.first {
//            self.sortKey = newSort
//            setDataManager()
//            tableView.reloadData()
//        }
	}
    
    private func saveFilters() {
        UserDefaults.standard.set(self.filters, forKey: "SegmentFilters")
    }
    
    private func savedFilters()->[PopupItem]? {
        return UserDefaults.standard.array(forKey: "SegmentFilters") as? [PopupItem]
    }

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "SegmentListToSegmentDetail", sender: self)
	}
    
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination.activeController as? SegmentDetailViewController {
			destination.segment = dataManager.objectAtIndexPath(tableView.indexPathForSelectedRow!)
		}
	}
	
}
