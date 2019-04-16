//
//  ViewProfileData.swift
//  RideViewer
//
//  Created by Home on 19/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

// Data structures for the view

enum ViewProfileDisplayType {
	case primary
	case secondary
	case background
	
	var displayColour : UIColor {
		switch self {
		case .primary:		return UIColor.black
		case .secondary:	return UIColor.green
		case .background:	return UIColor.lightGray
		}
	}
}

//     Range expressed in units on the primary axis
public struct RouteIndexRange {
    var from: Double
    var to: Double
}

struct DataPoint {
	var dataValue : Double
	var axisValue : Double
}

// Max / min for the dataSet to be plotted
struct DataBounds {
	var minX : Double
	var maxX : Double
	var minY : Double
	var maxY : Double
	
	func union(_ with: DataBounds) -> DataBounds {
		return DataBounds(minX: min(self.minX, with.minX),
						  maxX: max(self.maxX, with.maxX),
						  minY: min(self.minY, with.minY),
						  maxY: max(self.maxY, with.maxY))
	}
	
	func offsetBy(x : Double, y : Double) -> DataBounds {
		return DataBounds(minX: self.minX + x, maxX: self.maxX + x, minY: self.minY + y, maxY: self.maxY + y)
	}
	
	static var zeroBounds : DataBounds {
		return DataBounds(minX: Double.greatestFiniteMagnitude, maxX: 0.0, minY: Double.greatestFiniteMagnitude, maxY: 0.0)
	}
}

struct ViewProfileDataSet {
	var streamOwner : StreamOwner
	var profileDataType : RVStreamDataType
	var profileDisplayType : ViewProfileDisplayType
	var dataPoints : [DataPoint]
	
	var dataBounds: DataBounds {
		return DataBounds(minX: axisMin, maxX: axisMax, minY: dataMin, maxY: dataMax)
	}
	
	private var dataMin : Double {
		return dataPoints.reduce(Double.greatestFiniteMagnitude, { min($0, $1.dataValue) })
	}
	private var dataMax : Double {
		return dataPoints.reduce(0.0, { max($0, $1.dataValue) })
	}
	private var axisMin : Double {
		return dataPoints.reduce(Double.greatestFiniteMagnitude, { min($0, $1.axisValue) })
	}
	private var axisMax : Double {
		return dataPoints.reduce(0.0, { max($0, $1.axisValue) })
	}
}

struct ViewProfileData {
	private(set) var profileDataSets: [ViewProfileDataSet]
	private var plotBounds: DataBounds
	var viewRange : RouteIndexRange = RouteIndexRange(from: 0, to: 0)		// Referenced to the primary dataSet
	var highlightRange: RouteIndexRange?									// Referenced to the primary dataSet
	private(set) var rangeChangedHandler: ((RouteIndexRange) -> Void)?
	
	init(primaryDataSet : ViewProfileDataSet, handler : ((RouteIndexRange) -> Void)? = nil) {
		self.profileDataSets 		= [primaryDataSet]
		self.rangeChangedHandler	= handler
		self.highlightRange			= nil
		self.plotBounds				= primaryDataSet.dataBounds
	}
	
	mutating func addDataSet(_ dataSet : ViewProfileDataSet) {
		guard dataSet.profileDisplayType != .primary else {
			appLog.error("Adding primary dataSet")
			return
		}
		self.profileDataSets.append(dataSet)
		// TODO: Set the bounds of all the data sets
	}
	
	mutating func removeDataSetsOfDisplayType(_ type : ViewProfileDisplayType) {
		self.profileDataSets.removeAll(where: { $0.profileDisplayType == type })
	}
	
	var mainDataBounds : DataBounds {
		let dataSets = dataSetsOfDisplayType(.primary)  + dataSetsOfDisplayType(.secondary)
		let primaryBase = dataSetsOfDisplayType(.primary).first!.dataBounds.minX
		return dataSets.reduce(DataBounds.zeroBounds, ({  $0.union($1.dataBounds.offsetBy(x: primaryBase - $1.dataBounds.minX, y: 0.0)) }))
	}
	
	func dataSetsOfDataType(_ dataType : RVStreamDataType) -> [ViewProfileDataSet] {
		return self.profileDataSets.filter({ $0.profileDataType == dataType })
	}
	func dataSetsOfDisplayType(_ displayType : ViewProfileDisplayType) -> [ViewProfileDataSet] {
		return self.profileDataSets.filter({ $0.profileDisplayType == displayType })
	}
}

