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
        
        // Setup the data source
        dataManager.tableView = self.tableView
        self.filters = [.cycleRide(true), .virtualRide(true)]
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
        dataManager.filterPredicate = ActivityFilter.predicateForFilters(self.filters)
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
    
    private func newFilters(_ newFilters : [Filter]?)  {
        popupController?.dismiss(animated: true, completion: nil)
        if let returnedFilters = newFilters {			// nil means cancelled
            self.filters = returnedFilters
            //            saveFilters()
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
    }
    
}

// MARK: Filters
extension RVActivityListViewController {
    struct ActivityFilterValues : Codable {
        var dateFrom: Date
        var dateTo: Date
        var movingTime: RouteIndexRange
        var totalTime: RouteIndexRange
        var distance: RouteIndexRange
        var elevationGain: RouteIndexRange
        var averagePower: RouteIndexRange
        var totalEnergy: RouteIndexRange
    }
    
    func activityFilters() -> [Filter] {
        let values = savedFilters()
        
        return [
            Filter(name: "From", group: "Date", type: .date(("startDate",FilterComparison.greaterOrEqual, values.dateFrom))),
            Filter(name: "To", group: "Date", type: .date(("startDate",FilterComparison.lessOrEqual, values.dateTo))),
            Filter(name: "Moving", group: "Time", type: .range(("movingTime", values.movingTime))),
            Filter(name: "Total", group: "Time", type: .range(("elapsedTime", values.totalTime))),
            Filter(name: "Distance", group: "Ride", type: .range(("distance", values.distance))),
            Filter(name: "Elevation Gain", group: "Ride", type: .range(("elevationGain", values.elevationGain))),
            Filter(name: "Av. Power", group: "Ride", type: .range(("averagePower", values.averagePower))),
            Filter(name: "Total Energy", group: "Ride", type: .range(("kiloJoules", values.totalEnergy)))
        ]
    }
    
    private func saveFilters() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.filters) {
            UserDefaults.standard.set(encoded, forKey: "ActivityFilters")
        }
    }
    
    private func savedFilters()->ActivityFilterValues {
        if let savedFilters = UserDefaults.standard.object(forKey: "ActivityFilters") as? Data {
            let decoder = JSONDecoder()
            if let filters = try? decoder.decode(ActivityFilterValues.self, from: savedFilters) {
                return filters
            }
        }
        return RVActivity.filterDefaults()
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

