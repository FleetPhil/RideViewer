//
//  ActivityDetailViewController.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit

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
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		
		updateView()
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
		calories.text						= String(activity.calories)

		mapView!.showForActivity(activity)
		
		StravaManager.sharedInstance.updateActivity(activity, context: CoreDataManager.sharedManager().viewContext, completionHandler: {
			appLog.debug("Got activity details")
		})
		
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
		let filterPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(format: "activity.id == %@", argumentArray: [forActivity.id])])
		_ = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: filterPredicate)
	}

}
