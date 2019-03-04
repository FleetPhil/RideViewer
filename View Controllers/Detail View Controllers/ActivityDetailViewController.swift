//
//  ActivityDetailViewController.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import MapKit
import Photos
import StravaSwift
import CoreData

class ActivityDetailViewController: UIViewController, ScrollingPhotoViewDelegate {
	
	//MARK: Model
	weak var activity : RVActivity!
	
	@IBOutlet weak var tableView: RVTableView!
	
	@IBOutlet weak var distance: UILabel!
	@IBOutlet weak var startTime: UILabel!
	
	@IBOutlet weak var elevationData: UILabel!
	@IBOutlet weak var timeData: UILabel!
	@IBOutlet weak var powerData: UILabel!
	
	@IBOutlet weak var photoView: ScrollingPhotoView!
	
	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	var selectedEffort : RVEffort? = nil
	
	@IBOutlet weak var mapView: RideMapView! {
		didSet {
			mapView.mapType = .standard
			mapView.delegate = mapView
		}
	}
	
	// MARK: Profile View and data
	weak var routeViewController: RVRouteProfileViewController!

	// MARK: Photos
	private var photoAssets : [PHAsset] = []
	
	// MARK: Properties
	private var popupController : UIViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard activity != nil else { return }
		
		mapView.viewDelegate = self
		
		// Set scrolling photo view delegate
		photoView?.delegate = self
		
		// Set the route view controller
		
		
		// Get Strava details
		if activity.resourceState != .detailed {
			tableView.startDataRetrieval()
			StravaManager.sharedInstance.updateActivity(activity, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] success in
				if success {
					self?.tableView.endDataRetrieval()
				} else {
					self?.tableView.dataRetrievalFailed()
				}
			})
		}
		if activity.streams.count == 0 {
			appLog.verbose("Getting streams")
			StravaManager.sharedInstance.streamsForActivity(activity, context: activity.managedObjectContext!, completionHandler: { [weak self] success in
				if success, let streams = self?.activity.streams {
					appLog.verbose("Streams call result: success = \(success), \(streams.count) streams")
					for stream in streams {
						appLog.verbose("Stream \(stream.type!): \(stream.seriesType!), \(stream.dataPoints.count) data points")
					}
				} else {
					appLog.debug("Get streams failed for activity")
				}
                self?.routeViewController.setProfile(streamOwner: self!.activity, profileType: .altitude)
			})
		}
		
		if activity != nil {
			// Populate the view fields
			updateView()
		}
	}
	
	
	func updateView() {
		self.title 			= activity.name
		
		distance.text		= activity.distance.distanceDisplayString
		startTime.text		= (activity.startDate as Date).displayString(displayType: .dateTime, timeZone: activity.timeZone.timeZone)
		
		timeData.text		= "🕘 " + activity.elapsedTime.durationDisplayString
			+ " ⏱ " + activity.movingTime.durationDisplayString
			+ " ⏩ " + (activity.distance / activity.movingTime).speedDisplayString
		
		elevationData.text	= "⬇️ " + activity.lowElevation.heightDisplayString + " ⬆️ " + activity.highElevation.heightDisplayString + " ↗️ " + activity.elevationGain.heightDisplayString
		
		let powerAttributes : [NSAttributedString.Key : Any] = activity.deviceWatts ? [:] : [.foregroundColor : UIColor.lightGray]
		let powerText = NSMutableAttributedString(string: "Av:  " + String(activity.averagePower.fixedFraction(digits: 0)) + "W", attributes : powerAttributes)
		if activity.deviceWatts {
			powerText.append(NSAttributedString(string: ", Max: " + String(activity.maxPower.fixedFraction(digits: 0)) + "W"))
		}
		powerText.append(NSAttributedString(string: ", Total: " + String(activity.kiloJoules.fixedFraction(digits: 0)) + "kJ", attributes : powerAttributes))
		powerData.attributedText = powerText
		
		// Map view
		mapView!.addRoute(activity, type: .mainActivity)
		let predicate = RVEffort.filterPredicate(activity: activity, range: nil)
		let filteredEfforts = activity.efforts.filter { predicate.evaluate(with: $0) }
		
		appLog.debug("Filter reduces efforts from \(activity.efforts.count) to \(filteredEfforts.count)")
		
		filteredEfforts.forEach({
			mapView!.addRoute($0, type: .backgroundSegment)
		})
		mapView!.setMapRegion()
		
		// Get photos for this activity
		//        activity.getPhotoAssets(force: false, completionHandler: { [weak self] identifiers in
		//            identifiers.forEach() { [weak self] id in
		//                if self != nil {
		//                    _ = PhotoManager.shared().getPhotoImage(localIdentifier : id.localIdentifier, size : self!.photoView.bounds.size, resultHandler : { identifier, image, creationDate, location in
		//                        self?.photoView?.addImage(image: image, identifier: identifier)
		//                    })
		//                }
		//            }
		//        })
		
        routeViewController.setProfile(streamOwner: activity!, profileType: .altitude)
		
		setupEfforts(range: nil)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if activity != nil {
			mapView.setMapRegion()
		}
	}
	
	func imageHandler(identifier: String, image : UIImage?, photoDate: Date?, location: CLLocationCoordinate2D) {
		// appLog.debug("Returned image \(identifier)")
		photoView.addImage(image: image, identifier: identifier)
	}
	
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let destination = segue.destination as? SegmentDetailViewController {
			destination.segment = dataManager.objectAtIndexPath(tableView.indexPathForSelectedRow!)?.segment
		}
		if let destination = segue.destination as? RVRouteProfileViewController {
			self.routeViewController = destination
		}

	}
	
	// MARK: Scrolling photo view delegate
	func photoDidChangeToIndex(_ index: Int) {
		activity.getPhotoAssets(force: false, completionHandler: { [weak self] assets in
			let selectedPhotoAsset = assets[index]
			_ = PhotoManager.shared().getPhotoImage(localIdentifier: selectedPhotoAsset.localIdentifier,
													size: CGSize(width: 30, height: 30),
													resultHandler: { [ weak self]  _, image, _, location in
														self?.mapView.addPhoto(image: image, location: location)
			})
		})
	}
}

// MARK: Map view delegate
extension ActivityDetailViewController : RideMapViewDelegate {
	
	func didSelectRoute(route: RouteViewCompatible) {
		guard let effort = route as? RVEffort else {
			appLog.error("Unknown route")
			return
		}
		mapView.setTypeForRoute(route, type: .highlightSegment)
		
//		routeView.profileData?.highlightRange = effort.indexRange
		
		if let indexPathForSelectedRoute = dataManager.indexPathForObject(effort) {
			tableView.selectRow(at: indexPathForSelectedRoute, animated: true, scrollPosition: .middle)
		}
	}
	
	func didDeselectRoute(route: RouteViewCompatible) {
		guard route as? RVEffort != nil else {
			appLog.error("Unknown route")
			return
		}
		mapView.setTypeForRoute(route, type: .backgroundSegment)
		
//		routeView.profileData?.highlightRange = nil
	}
	
	func newIndexRange(_ range : RouteIndexRange) {
		appLog.verbose("Index range now \(range.from) to \(range.to)")
		
		dataManager.filterPredicate = RVEffort.filterPredicate(activity: activity, range: range)
		_ = dataManager.fetchObjects()
		tableView.reloadData()
		
		if let effort = self.selectedEffort {
			if let path = dataManager.indexPathForObject(effort) {
				tableView.selectRow(at: path, animated: true, scrollPosition: .middle)
			}
		}
		
		// Update the map view
		for path in tableView.indexPathsForVisibleRows ?? [] {
			if let effort = dataManager.objectAtIndexPath(path) {
				if effort == self.selectedEffort {
					mapView.addRoute(effort.segment, type: .highlightSegment)
				} else {        // Not selected effort
					mapView.addRoute(effort.segment, type: .backgroundSegment)
				}
			}
		}
	}
	
	func didChangeVisibleRoutes(_ routes: [RouteViewCompatible]) {
		// TODO: 
		return
		
		
		// remember the selected effort if there is one
//		var selectedEffort : RVEffort? = nil
//		if let indexPath = tableView.indexPathForSelectedRow {
//			selectedEffort = dataManager.objectAtIndexPath(indexPath)
//		}
//
//		let efforts = routes.filter({ $0 is RVEffort }) as! [RVEffort]
//		let range = RouteIndexRange(from: Int(efforts.reduce(Int64.max, { min($0, $1.startIndex) })), to: Int(efforts.reduce(0, { max($0, $1.startIndex)})))
//
//		dataManager.filterPredicate = RVEffort.filterPredicate(activity: activity, range: range)
//		_ = dataManager.fetchObjects()
//		tableView.reloadData()
//
//		// Reselect the effort if it's still in scope
//		if let selectedEffort = selectedEffort {
//			if let indexPath = dataManager.indexPathForObject(selectedEffort) {
//				tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
//			} else {
//				mapView.setTypeForRoute(selectedEffort, type: .backgroundSegment)
//			}
//		}
//		if routeView.profileData != nil {
//			routeView.profileData!.highlightRange = range
//		}
	}
}

// MARK: Effort table support
extension ActivityDetailViewController : SortFilterDelegate {
	
	func setupEfforts(range : RouteIndexRange?) {
		tableView.dataSource    = dataManager
		tableView.rowHeight 	= UITableView.automaticDimension
		tableView.sortFilterDelegate = self
		tableView.tag = EffortTableViewType.effortsForActivity.rawValue
		
		dataManager.tableView = tableView
		
		dataManager.sortDescriptor = NSSortDescriptor(key: EffortSort.sequence.rawValue, ascending: EffortSort.sequence.defaultAscending)
		dataManager.filterPredicate = RVEffort.filterPredicate(activity: activity, range: nil)
		
		_ = dataManager.fetchObjects()
		tableView.reloadData()
		self.selectedEffort = nil
	}
	
	func tableRowSelectedAtIndex(_ index: IndexPath) {
		guard let effort = dataManager.objectAtIndexPath(index) else { return }
		self.selectedEffort = effort
		
		mapView.setTypeForRoute(effort, type: .highlightSegment)
		
//		routeView.profileData?.highlightRange = effort.indexRange
	}
	
	func tableRowDeselectedAtIndex(_ index : IndexPath) {
		guard let effort = dataManager.objectAtIndexPath(index) else { return }
		self.selectedEffort = nil
		
		mapView.setTypeForRoute(effort, type: .backgroundSegment)
		
//		routeView.profileData?.highlightRange = nil
	}
	
	func didScrollToVisiblePaths(_ paths : [IndexPath]?) {
		
	}
	
	func sortButtonPressed(sender: UIView) {
		// Popup the list of fields to select sort order
		let chooser = PopupupChooser<EffortSort>()
		chooser.title = "Sort order"
		popupController	= chooser.showSelectionPopup(items: EffortSort.allCases, sourceView: sender, updateHandler: newSortOrder)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	func filterButtonPressed(sender: UIView) {
		let chooser = PopupupChooser<EffortFilter>()
		chooser.title = "Include"
		chooser.multipleSelection = true
		chooser.selectedItems = EffortFilter.allCases		// self.filters
		popupController = chooser.showSelectionPopup(items: EffortFilter.allCases, sourceView: sender, updateHandler: newFilters)
		if popupController != nil {
			present(popupController!, animated: true, completion: nil)
		}
	}
	
	func contentChanged() {
		
	}
	
	private func newFilters(_ newFilters : [EffortFilter]?)  {
		popupController?.dismiss(animated: true, completion: nil)
		if let selectedFilters = newFilters {
			dataManager.filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [RVEffort.filterPredicate(activity: activity, range: nil),
																						  EffortFilter.predicateForFilters(selectedFilters)])
			_ = dataManager.fetchObjects()
			tableView.reloadData()
		}
	}
	
	
	private func newSortOrder(newOrder : [EffortSort]?) {
		popupController?.dismiss(animated: true, completion: nil)
		if let newSort = newOrder?.first {
			dataManager.sortDescriptor = NSSortDescriptor(key: newSort.rawValue, ascending: newSort.defaultAscending)
			_ = dataManager.fetchObjects()
			tableView.reloadData()
		}
	}
}


