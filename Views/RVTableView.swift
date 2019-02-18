//
//  RVTableView.swift
//  RideViewer
//
//  Created by Home on 04/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

// MARK: RVTableView

protocol SortFilterDelegate : class {
	func tableRowSelectedAtIndex(_ index : IndexPath)
	func tableRowDeselectedAtIndex(_ index : IndexPath)
	func didScrollToVisiblePaths(_ paths : [IndexPath]?)
	
	func sortButtonPressed(sender : UIView)
	func filterButtonPressed(sender : UIView)
}

// Default behaviour for optional functions
extension SortFilterDelegate {
	func tableRowDeselectedAtIndex(_ index : IndexPath) {
		return
	}
}

class RVTableView : UITableView, UITableViewDelegate {
	weak var sortFilterDelegate : SortFilterDelegate?
	var activityIndicator : UIActivityIndicatorView!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.delegate = self
	}
	
	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		self.delegate = self
	}
	
	// Tableview delegate methods
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		sortFilterDelegate?.tableRowSelectedAtIndex(indexPath)
	}
	
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		sortFilterDelegate?.tableRowDeselectedAtIndex(indexPath)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView()
		headerView.backgroundColor = UIColor.lightGray
		return headerView
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			sortFilterDelegate?.didScrollToVisiblePaths(self.indexPathsForVisibleRows)
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let sortButton = UIButton(frame: CGRect(x: 20, y: 0, width: 44, height: view.bounds.maxY))
		sortButton.setTitle("Sort", for: .normal)
		sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
		view.addSubview(sortButton)
		
		let filterButton = UIButton(frame: CGRect(x: view.bounds.maxX - 64, y: 0, width: 44, height: view.bounds.maxY))
		filterButton.setTitle("Filter", for: .normal)
		filterButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
		view.addSubview(filterButton)
	}
	
	@IBAction func sortButtonPressed(sender : UIButton) {
		sortFilterDelegate?.sortButtonPressed(sender: sender)
	}
	
	@IBAction func filterButtonPressed(sender : UIButton) {
		sortFilterDelegate?.filterButtonPressed(sender: sender)
	}
	
	func startDataRetrieval() {
		activityIndicator = UIActivityIndicatorView(style: .gray)
		activityIndicator.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
		self.addSubview(activityIndicator)
		activityIndicator.startAnimating()
		self.bringSubviewToFront(activityIndicator)
	}
	
	func endDataRetrieval() {
		activityIndicator.stopAnimating()
	}
	
	func dataRetrievalFailed() {
		activityIndicator.stopAnimating()
		// Display an alert view
		let alert = UIAlertController(title: "", message: "Unable to get Strava Update", preferredStyle: .alert)
		UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
			alert.dismiss(animated: true, completion: nil)
		}
	}
}
