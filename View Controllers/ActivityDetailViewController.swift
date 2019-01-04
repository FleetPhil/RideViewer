//
//  ActivityDetailViewController.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import MapKit

class ActivityDetailViewController: ListViewMaster, UITableViewDelegate {
	
	//MARK: Model
	var activity : RVActivity!
	
	@IBOutlet weak var activityDescription: UILabel!
	@IBOutlet weak var distance: UILabel!
	@IBOutlet weak var startTime: UILabel!
	@IBOutlet weak var elapsedTime: UILabel!
	@IBOutlet weak var movingTime: UILabel!
	@IBOutlet weak var elevationGain: UILabel!
	@IBOutlet weak var startLocation: UILabel!
	@IBOutlet weak var endLocation: UILabel!
	@IBOutlet weak var averageSpeed: UILabel!
	@IBOutlet weak var calories: UILabel!
	
	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	
	@IBOutlet weak var mapView: RideMapView! {
		didSet {
			mapView.mapType = .standard
			mapView.delegate = mapView
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if activity != nil {
			updateView()
		}
    }
	
	func updateView() {
		self.title 							= activity.name
		//		activityDescription.text			= activity.activityDescription ?? ""
		distance.text						= activity.distance.distanceDisplayString
		startTime.text						= (activity.startDate as Date).displayString()
		elapsedTime.text					= activity.elapsedTime.durationDisplayString
		movingTime.text						= activity.movingTime.durationDisplayString
		elevationGain.text					= activity.elevationGain.heightDisplayString
		startLocation.text					= String(activity.startLocation.latitude) + " " + String(activity.startLocation.longitude)
		endLocation.text					= String(activity.endLocation.latitude) + " " + String(activity.endLocation.longitude)
		averageSpeed.text					= activity.averageSpeed.speedDisplayString
		calories.text						= String(activity.kiloJoules) + "kJ"

		mapView!.showForActivity(activity)
		
		switch activity.resourceState {
		case .detailed:
			break
		default:
			StravaManager.sharedInstance.updateActivity(activity,
                context: CoreDataManager.sharedManager().viewContext, completionHandler: {
				appLog.debug("Got detailed activity")
			})
		}
		setupEfforts(activity)
	}
	
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ActivityDetailViewController {
	// MARK: effort table view support

	func setupEfforts(_ forActivity : RVActivity) {
		tableView.dataSource    = dataManager
		tableView.delegate      = self
		tableView.rowHeight = UITableView.automaticDimension
		
		dataManager.delegate = self
		
		let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: false)
		let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
		let filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "activity.id == %@", argumentArray: [forActivity.id]), settingsPredicate])
		_ = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: filterPredicate)
	}

}
