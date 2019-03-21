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
enum ViewProfileDataType : String {
	case speed 		= "velocity_smooth"
	case altitude
	case heartRate 	= "heartrate"
	case power 		= "watts"
	case distance
	case cadence
	
	var stravaValue : String {
		return self.rawValue
	}
}

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
	var profileDataType : ViewProfileDataType
	var profileDisplayType : ViewProfileDisplayType
	var dataPoints : [DataPoint]
	
	var fullRange : RouteIndexRange {
		return RouteIndexRange(from: (self.dataPoints.map { $0.axisValue }).min() ?? 0, to: (self.dataPoints.map { $0.axisValue }).max() ?? 0)
	}
	
	func rangeInScope(viewRange : RouteIndexRange, primaryRange : RouteIndexRange) -> RouteIndexRange {
		let minX =  (self.dataPoints.map { $0.axisValue }).min() ?? 0
		// Range min for this dataSet is primary min + offset for this set + offset for view from primary min
		// Reduces to view min + this min - primary min
		let scopeMin = viewRange.from + minX - primaryRange.from
		return RouteIndexRange(from: scopeMin, to: primaryRange.to)
	}
	
	func dataPointsInScope(viewRange : RouteIndexRange, primaryRange : RouteIndexRange) -> [DataPoint] {
		let range = rangeInScope(viewRange: viewRange, primaryRange: primaryRange)
		return dataPoints.filter({ $0.axisValue >= range.from && $0.axisValue <= range.to })
	}
	
	func dataBounds(viewRange : RouteIndexRange) -> DataBounds {
		return DataBounds(minX: axisMin(viewRange: viewRange), maxX: axisMax(viewRange: viewRange), minY: dataMin(viewRange: viewRange), maxY: dataMax(viewRange: viewRange))
	}
	
	func dataMin(viewRange : RouteIndexRange) -> Double {
		return dataPointsInScope(viewRange: viewRange, primaryRange: self.fullRange).reduce(Double.greatestFiniteMagnitude, { min($0, $1.dataValue) })
	}
	func dataMax(viewRange : RouteIndexRange) -> Double {
		return dataPointsInScope(viewRange: viewRange, primaryRange: self.fullRange).reduce(0.0, { max($0, $1.dataValue) })
	}
	func axisMin(viewRange : RouteIndexRange) -> Double {
		return dataPointsInScope(viewRange: viewRange, primaryRange: self.fullRange).reduce(Double.greatestFiniteMagnitude, { min($0, $1.axisValue) })
	}
	func axisMax(viewRange : RouteIndexRange) -> Double {
		return dataPointsInScope(viewRange: viewRange, primaryRange: self.fullRange).reduce(0.0, { max($0, $1.axisValue) })
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
		self.plotBounds				= {
			let range = primaryDataSet.fullRange
			return DataBounds(minX: primaryDataSet.axisMin(viewRange: range),
							  maxX: primaryDataSet.axisMin(viewRange: range),
							  minY: primaryDataSet.dataMin(viewRange: range),
							  maxY: primaryDataSet.dataMax(viewRange: range))
		}()
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
		let primaryBase = dataSetsOfDisplayType(.primary).first!.axisMin(viewRange: viewRange)
		return dataSets.reduce(DataBounds.zeroBounds, ({  $0.union($1.dataBounds(viewRange: viewRange).offsetBy(x: primaryBase - $1.axisMin(viewRange: viewRange), y: 0.0)) }))
	}
	
	func dataSetsOfDataType(_ dataType : ViewProfileDataType) -> [ViewProfileDataSet] {
		return self.profileDataSets.filter({ $0.profileDataType == dataType })
	}
	func dataSetsOfDisplayType(_ displayType : ViewProfileDisplayType) -> [ViewProfileDataSet] {
		return self.profileDataSets.filter({ $0.profileDisplayType == displayType })
	}
}

