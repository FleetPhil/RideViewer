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

class SegmentListViewController: ListViewMaster, UITableViewDelegate {
	
	// MARK: Model
	private lazy var dataManager = DataManager<RVSegment>()
	
	// MARK: Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = "Segments"
		tableView.dataSource    = dataManager
		tableView.delegate      = self
		tableView.rowHeight = UITableView.automaticDimension
		
		dataManager.delegate = self
		
		let sortDescriptor = NSSortDescriptor(key: "distance", ascending: false)
		_ = dataManager.fetchObjects(sortDescriptor: sortDescriptor, filterPredicate: nil)
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		performSegue(withIdentifier: "SegmentListToSegmentDetail", sender: self)
	}
	
	// MARK: - Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		if let destination = segue.destination.activeController as? SegmentDetailViewController {
//			destination.activity = dataManager.objectAtIndexPath(tableView.indexPathForSelectedRow!)
//		}
	}
	
}
