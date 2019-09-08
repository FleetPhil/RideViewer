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

class RVActivityListViewController: UIViewController, UITableViewDelegate, FilterDelegate {
    
    // MARK: Model
    private lazy var dataManager = DataManager<RVActivity>()
    
    // Outlets
    @IBOutlet weak var tableView: RVSortFilterTableView!
    var tableDataIsComplete = true
    
    // Properties
    private var filters : [Filter]!
    private var sortKey : ActivitySort!
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Activities"
        
        // Set table view parameters
        tableView.dataSource    = dataManager
        tableView.delegate		= self
        
        // Setup the data source
        dataManager.tableView = self.tableView
        self.filters = activityFilters()
        self.sortKey = .date
        setDataManager()
        
        if let activities : [RVActivity] = CoreDataManager.sharedManager().viewContext.fetchObjects() {
            if let lastActivityDate = activities.map({ $0.startDate as Date }).max() {
                appLog.debug("\(activities.count) activities stored ")
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
        dataManager.filterPredicate = Filter.predicateForFilters(self.filters)
        dataManager.sortDescriptor = NSSortDescriptor(key: self.sortKey.rawValue, ascending: self.sortKey.defaultAscending)
        _ = dataManager.fetchObjects()
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
        let picker = StringPicker(title: "Sort", choices: ActivitySort.allCases.map({ $0.selectionLabel }))
            .setDoneButtonAction({ _, rowIndex, selectedString in
                self.sortKey = ActivitySort.allCases[rowIndex]
                self.setDataManager()
                self.tableView.reloadData()
            })
        picker.appear(originView: sender, baseViewController: self)
    }
    
    @objc func filterButtonPressed(sender: UIView) {
        performSegue(withIdentifier: "ActivityListToFilter", sender: self)
    }
    
    func newFilters(_ newFilters : [Filter]?)  {
        if let returnedFilters = newFilters {			// nil means cancelled
            self.filters = returnedFilters
            saveFilterValues(filterValues: valuesForFilters(self.filters), key: SettingsConstants.ActivityFilterKey)
            setDataManager()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        // Set current filters for update
        if let destination = segue.destination.activeController as? FilterViewController {
            destination.delegate = self
            destination.filters = self.filters
        }
        
    }
    
}

// MARK: Filters
extension RVActivityListViewController {
    func activityFilters() -> [Filter] {
        guard let limits = RVActivity.filterLimits(context: CoreDataManager.sharedManager().viewContext) else { return [] }        // No data
        let values = savedFilterValues(key: SettingsConstants.ActivityFilterKey) ?? limits
        
        return FilterDefinition.filtersforType(SettingsConstants.ActivityFilterKey, values: values, limits: limits) ?? []
    }
}

