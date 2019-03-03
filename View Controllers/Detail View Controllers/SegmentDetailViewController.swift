//
//  SegmentDetailViewController.swift
//  RideViewer
//
//  Created by Home on 05/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData
import StravaSwift

class SegmentDetailViewController: UIViewController {
    
    //MARK: Model
    var segment : RVSegment!
    
    // MARK: Model for effort table
    private lazy var dataManager = DataManager<RVEffort>()
    
    @IBOutlet weak var tableView: RVTableView!
    
    @IBOutlet weak var effortsLabel: UILabel!
    
    @IBOutlet weak var mapView: RideMapView! {
        didSet {
            mapView.mapType = .standard
            mapView.delegate = mapView
        }
    }
    
    @IBOutlet weak var routeViewController: RVRouteProfileViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sortFilterDelegate = self
        
        if segment != nil {
            updateView()
        }
    }
    
    func updateView() {
        self.title 				= segment.name
        
        self.effortsLabel.text	= "\(tableView.numberOfRows(inSection: 0)) Efforts"
        self.effortsLabel.textColor = segment.resourceState.resourceStateColour
		
		// Update map
        if segment.map != nil {
			self.mapView.addRoute(segment, type: .highlightSegment)
		} else {
            // Get segment details including route
            StravaManager.sharedInstance.getSegment(segment, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
                guard self != nil else { return }
                if success {
                    self!.mapView!.addRoute(self!.segment, type: .highlightSegment)
                }
            })
        }
        
        // Get all efforts for this segment if we don't have them
        if !segment.allEfforts {
            StravaManager.sharedInstance.effortsForSegment(self.segment, page: 1, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [ weak self ] success in
                self?.effortsLabel.text    = "\(self?.tableView.numberOfRows(inSection: 0) ?? 0) Efforts"
            })
        }
		// Fetched results controller will update the table once it is set up
        setupEfforts(segment)
		
		
		// Get the route altitude profile
		if segment.streams.filter({ $0.type! == StreamType.altitude.rawValue }).first != nil {
            routeViewController.setProfile(streamOwner: segment, profileType: .altitude)
		}
		
    }
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVRouteProfileViewController {
			self.routeViewController = destination
		}
		
	}

}

extension SegmentDetailViewController : SortFilterDelegate {
    // MARK: effort table view support
    
    func setupEfforts(_ forSegment : RVSegment) {
        tableView.dataSource    = dataManager
        tableView.rowHeight 	= UITableView.automaticDimension
        
        tableView.tag = EffortTableViewType.effortsForSegment.rawValue
        dataManager.tableView = tableView
        setDataManager(sortKey: .movingTime, ascending: EffortSort.movingTime.defaultAscending)
    }
    
    func setDataManager(sortKey : EffortSort, ascending :  Bool) {
        dataManager.sortDescriptor = NSSortDescriptor(key: sortKey.rawValue, ascending: ascending)
        
        let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
        let filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "segment.id == %@", argumentArray: [segment.id]), settingsPredicate])
        dataManager.filterPredicate = filterPredicate
        let efforts = dataManager.fetchObjects()
        self.effortsLabel.text = "\(efforts.count) Efforts"
    }
    
    func tableRowDeselectedAtIndex(_ index: IndexPath) {
        let activity = dataManager.objectAtIndexPath(index)!.activity
        self.mapView.setTypeForRoute(activity, type: .backgroundSegment)
    }
    
    func tableRowSelectedAtIndex(_ index: IndexPath) {
        let effort = dataManager.objectAtIndexPath(index)!
        self.mapView.addRoute(effort.activity, type: .highlightSegment)
        
        setViewforEffort(effort)
        if effort.activity.streams.count == 0 {
            // Get streams
            StravaManager.sharedInstance.streamsForActivity(effort.activity, context: effort.managedObjectContext!, completionHandler: { [ weak self] success in
                if success {
                    self?.setViewforEffort(effort)
                } else {
                    appLog.debug("Failed to get stream data for activity \(effort.activity) ")
                }
            })
        }
        
        //		performSegue(withIdentifier: "SegmentEffortListToSegmentDetail", sender: self)
    }
    
    private func setViewforEffort(_ effort : RVEffort) {
		var profileData = ViewProfileData(handler: nil)
        
        if let altitudeStream = (effort.activity.streams.filter { $0.type == StravaSwift.StreamType.altitude.rawValue }).first {
            let dataStream = altitudeStream.dataPoints.sorted(by: { $0.index < $1.index }).map({ $0.dataPoint })
            profileData.addDataSet(ViewProfileDataSet(profileDataType: .altitude, profileDataPoints: dataStream ))
        }
        routeViewController.setProfile(streamOwner: effort, profileType: .altitude)
		
		// TODO: set up highglight
//        routeView.profileData?.highlightRange = effort.indexRange
    }
    
    func didScrollToVisiblePaths(_ paths : [IndexPath]?) {
        
    }
    
    func sortButtonPressed(sender: UIView) {
        // Popup the list of fields to select sort order
        let chooser = PopupupChooser<EffortSort>()
        chooser.title = "Select sort order"
        chooser.showSelectionPopup(items: EffortSort.allCases,
                                   sourceView: sender,
                                   updateHandler: newSortOrder)
    }
    
    func filterButtonPressed(sender: UIView) {
        
    }
    
    private func newSortOrder(newOrder : [EffortSort]) {
        if let newSort = newOrder.first {
            setDataManager(sortKey: newSort, ascending: newSort.defaultAscending)
            tableView.reloadData()
        }
    }
    
    
    
}

