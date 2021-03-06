//
//  RVSortFilterTableView.swift
//  RideViewer
//
//  Created by Home on 11/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class RVSortFilterTableView: UITableView {
	// Public properties
	var sectionHeaderView : RVSortFilterHeaderView?
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView()
		headerView.backgroundColor = UIColor.lightGray
		return headerView
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		sectionHeaderView = RVSortFilterHeaderView(frame: view.bounds)
		sectionHeaderView!.headerLabel.text = "Header"
		view.addSubview(sectionHeaderView!)
	}
}

class RVSortFilterHeaderView : UIView {
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
		
		headerLabel = UILabel(frame: CGRect(x: self.bounds.midX - 30, y: 0, width: self.bounds.width - 104, height: self.bounds.maxY))
		headerLabel.textColor = .white
		self.addSubview(headerLabel)
	}
	
	
}
