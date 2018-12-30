//
//  Data Model Extensions.swift
//  RideViewer
//
//  Created by Home on 29/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

@objc public enum ResourceState : Int16 {
	case undefined 	= 0
	case meta 		= 1
	case summary	= 2
	case detailed	= 3
}
