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
	
	var tableDataIsComplete : Bool { get }
}

// Default behaviour for optional functions
extension SortFilterDelegate {
	func tableRowDeselectedAtIndex(_ index : IndexPath) {
		return
	}
}

class RVTableView : UITableView, UITableViewDelegate {
	weak var sortFilterDelegate : SortFilterDelegate?
	
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
		let header = SortFilterHeaderView(frame: view.bounds)
		header.sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
		header.filterButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
		header.headerLabel.text = "\(tableView.numberOfRows(inSection: 0))" + (sortFilterDelegate?.tableDataIsComplete == false ? "+" : "")
		view.addSubview(header)
	}
	
	@IBAction func sortButtonPressed(sender : UIButton) {
		sortFilterDelegate?.sortButtonPressed(sender: sender)
	}
	
	@IBAction func filterButtonPressed(sender : UIButton) {
		sortFilterDelegate?.filterButtonPressed(sender: sender)
	}
	
}

class SortFilterHeaderView : UIView {
	var sortButton : UIButton!
	var filterButton : UIButton!
	var headerLabel : UILabel!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initSubviews()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		initSubviews()
	}
	
	func initSubviews() {
		sortButton = UIButton(frame: CGRect(x: 8, y: 0, width: 44, height: self.bounds.maxY))
		sortButton.setTitle("Sort", for: .normal)
		self.addSubview(sortButton)
		
		filterButton = UIButton(frame: CGRect(x: self.bounds.maxX - 52, y: 0, width: 44, height: self.bounds.maxY))
		filterButton.setTitle("Filter", for: .normal)
		self.addSubview(filterButton)
		
		headerLabel = UILabel(frame: CGRect(x: self.bounds.midX - 20, y: 0, width: 40, height: self.bounds.maxY))
		headerLabel.textColor = .white
		self.addSubview(headerLabel)
	}
	

}
