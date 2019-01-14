//
//  SegmentDetailViewController.swift
//  RideViewer
//
//  Created by Home on 05/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData

class SegmentDetailViewController: ListViewMaster, UITableViewDelegate {
	
	//MARK: Model
	var segment : RVSegment!

	// MARK: Model for effort table
	private lazy var dataManager = DataManager<RVEffort>()
	
	@IBOutlet weak var effortsLabel: UILabel!
	
	@IBOutlet weak var mapView: RideMapView! {
		didSet {
			mapView.mapType = .standard
			mapView.delegate = mapView
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if segment != nil {
			updateView()
		}
	}
	
	func updateView() {
		self.title 				= segment.name
		
		self.effortsLabel.text	= "\(tableView.numberOfRows(inSection: 0)) Efforts"
		
		mapView!.showForRoute(segment)
		
		if segment.resourceState != .detailed {
			StravaManager.sharedInstance.updateSegment(segment, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] in
				if let currentSelf = self {
					currentSelf.mapView!.showForRoute(currentSelf.segment)
				}
			})
		}

		if StravaManager.sharedInstance.haveNewActivities == .yes {
			StravaManager.sharedInstance.effortsForSegment(segment, page: 1, context: CoreDataManager.sharedManager().viewContext, completionHandler: { [weak self] in
				self?.setupEfforts(self!.segment)
			} )
		}
		setupEfforts(segment)
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

extension SegmentDetailViewController {
	// MARK: effort table view support
	
	func setupEfforts(_ forSegment : RVSegment) {
		tableView.dataSource    = dataManager
		tableView.delegate      = self
		tableView.rowHeight 	= UITableView.automaticDimension
		
		tableView.tag = EffortTableViewType.effortsForSegment.rawValue
		
		dataManager.delegate = self
		
		let sortDescriptor = NSSortDescriptor(key: "startIndex", ascending: true)
		let settingsPredicate = Settings.sharedInstance.segmentSettingsPredicate
		let filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "segment.id == %@", argumentArray: [forSegment.id]), settingsPredicate])
		let efforts = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: filterPredicate)
		self.effortsLabel.text = "\(efforts.count) Efforts"
	}
	
}

