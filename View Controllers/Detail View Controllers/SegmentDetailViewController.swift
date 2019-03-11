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
	private var effortFilters : [EffortFilter] = []
	private var effortSort : EffortSort = .elapsedTime
	
	@IBOutlet weak var distanceLabel: UILabel!
	@IBOutlet weak var elevationLabel: UILabel!
	
    @IBOutlet weak var tableView: RVTableView!
	var tableDataIsComplete = false
	
    @IBOutlet weak var mapView: RideMapView! {
        didSet {
            mapView.mapType = .standard
            mapView.delegate = mapView
        }
    }
    
    @IBOutlet weak var routeViewController: RVRouteProfileViewController!
	
	private var popupController : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sortFilterDelegate = self
        
        if segment != nil {
            updateView()
        }
    }
    
    func updateView() {
		
		let segmentStarText = segment.starred ? "★" : "☆"
        self.title 				= segmentStarText + " " + segment.name!
        
		distanceLabel.text = segment.distance.distanceDisplayString
		elevationLabel.text	= " ↗️ " + segment.elevationGain.heightDisplayString + " " + segment.averageGrade.fixedFraction(digits: 1) + "%"
		
		// Update map
        if segment.map != nil {
			self.mapView.addRoute(segment, type: .highlightSegment)
		} else {
            // Get segment details including route
            StravaManager.sharedInstance.getSegment(segment, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
                guard self != nil else { return }
                if success {
                    self!.mapView!.addRoute(self!.segment, type: .highlightSegment)
				} else {		// If route not found will zoom to start/end annotations
					self?.mapView.addRoute(self!.segment, type: .highlightSegment)
				}
            })
        }
        
        // Get all efforts for this segment if we don't have them
        if segment.allEfforts {
			tableDataIsComplete = true
		} else {
            StravaManager.sharedInstance.effortsForSegment(self.segment, page: 1, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [ weak self ] success in
				if success {
					self?.tableDataIsComplete = true
				}
            })
        }
		// Fetched results controller will update the table once it is set up
        setupEfforts(segment)
		
		// Get the route altitude profile
		if segment.hasStreamOfType(.altitude) {
            routeViewController.setPrimaryProfile(streamOwner: segment, profileType: .altitude)
		} else {
			appLog.verbose("Getting streams")
			StravaManager.sharedInstance.streamsForSegment(segment, context: segment.managedObjectContext!, completionHandler: { [weak self] success in
				if success, let streams = self?.segment.streams {
					appLog.verbose("Streams call result: success = \(success), \(streams.count) streams")
				} else {
					appLog.verbose("Get streams failed for activity")
				}
				self?.routeViewController.setPrimaryProfile(streamOwner: self!.segment, profileType: .altitude)
			})
		}
    }
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? RVRouteProfileViewController {		// Embed segue
			self.routeViewController = destination
			return
		}
		
		if let destination = segue.destination as? SegmentAnalysisViewController {
			destination.segment = segment
			return
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
        setDataManager()
    }
    
    func setDataManager() {
        dataManager.sortDescriptor = NSSortDescriptor(key: effortSort.rawValue, ascending: effortSort.defaultAscending)
        
        let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
        let segmentPredicate = NSPredicate(format: "segment.id == %@", argumentArray: [segment.id])
		let effortPredicate = EffortFilter.predicateForFilters(self.effortFilters)
        dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [settingsPredicate, segmentPredicate, effortPredicate])
        let _ = dataManager.fetchObjects()
    }
    
    func tableRowDeselectedAtIndex(_ index: IndexPath) {
        let activity = dataManager.objectAtIndexPath(index)!.activity
        self.mapView.setTypeForRoute(activity, type: nil)
    }
    
    func tableRowSelectedAtIndex(_ index: IndexPath) {
        let effort = dataManager.objectAtIndexPath(index)!
        self.mapView.addRoute(effort.activity, type: .highlightSegment)
    }
    
    func didScrollToVisiblePaths(_ paths : [IndexPath]?) {
        
    }
    
    func sortButtonPressed(sender: UIView) {
        // Popup the list of fields to select sort order
        let chooser = PopupupChooser<EffortSort>()
        chooser.title = "Select sort order"
        popupController = chooser.showSelectionPopup(items: EffortSort.sortOptionsForSegment, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
    }
    
    func filterButtonPressed(sender: UIView) {
		let chooser = PopupupChooser<EffortFilter>()
		chooser.title = "Include"
		chooser.multipleSelection = true
		chooser.selectedItems = self.effortFilters
		popupController = chooser.showSelectionPopup(items: [], sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
    }
    
    private func newSortOrder(newOrder : [EffortSort]?) {
		popupController?.dismiss(animated: true, completion: nil)
        if let newSort = newOrder?.first {
			self.effortSort = newSort
			setDataManager()
            tableView.reloadData()
        }
    }
	
	private func newFilters(_ newFilters : [EffortFilter]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		if let selectedFilters = newFilters {
			self.effortFilters = selectedFilters
			setDataManager()
			tableView.reloadData()
		}
	}

    
    
}

