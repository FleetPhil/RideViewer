//
//  Data Model Extensions.swift
//  RideViewer
//
//  Created by Home on 29/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import UIKit
import StravaSwift

// Protocols to make entities list view compatible
protocol TableViewCompatibleEntity {
	func cellForTableView(tableView: UITableView, atIndexPath indexPath: IndexPath) -> TableViewCompatibleCell
}

protocol TableViewCompatibleCell {
    func configure(withModel : TableViewCompatibleEntity) -> TableViewCompatibleCell
}

@objc public enum RVResourceState : Int16 {
	case undefined 	= 0
	case meta 		= 1
	case summary	= 2
	case detailed	= 3
    
    // calculate new resource state - existing state always takes priority...
    func newState(returnedState : ResourceState?) -> RVResourceState {
        guard returnedState != nil else { return self }
        switch returnedState! {
        case .meta:        return self == .undefined ? .meta : self
        case .summary:     return self == .detailed ? self : .summary
        case .detailed:    return .detailed
        }
    }
	
	var resourceStateColour : UIColor {
		switch self {
		case .undefined: 	return UIColor.red
		case .meta:			return UIColor.darkGray
		case .summary: 		return UIColor.blue
		case .detailed:		return UIColor.green
		}
	}
}
