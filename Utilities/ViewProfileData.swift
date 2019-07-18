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
    case notShown
	
	var displayColour : UIColor {
		switch self {
		case .primary:		return DisplayConstants.PrimaryProfileColour
		case .secondary:	return DisplayConstants.SecondaryProfileColour
		case .background:	return UIColor.lightGray
        case .notShown:     return UIColor.red
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
	
	init (dataValue: Double, axisValue : Double) {
		self.dataValue = dataValue
		self.axisValue = axisValue
	}
	
	init? (data: Double?, axis: Double?) {
		if let data = data, let axis = axis {
			self.axisValue = axis
			self.dataValue = data
		} else {
			return nil
		}
	}
}

extension DataPoint : Equatable {
    static func == (lhs : DataPoint, rhs : DataPoint) -> Bool {
        return (lhs.axisValue == rhs.axisValue) && (lhs.dataValue == rhs.dataValue)
    }
}

struct ViewProfileDataSet {
	var streamOwner : StreamOwner
	var profileDataType : RVStreamDataType
	var profileDisplayType : ViewProfileDisplayType
	var dataPoints : [DataPoint]
	
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
    private(set) var profileSeriesType : RVStreamDataType
	var viewRange : RouteIndexRange = RouteIndexRange(from: 0, to: 0)		// Referenced to the primary dataSet
	var highlightRange: RouteIndexRange?									// Referenced to the primary dataSet
	private(set) var rangeChangedHandler: ((RouteIndexRange) -> Void)?
	
    init(primaryDataSet : ViewProfileDataSet, seriesType : RVStreamDataType, handler : ((RouteIndexRange) -> Void)? = nil) {
		self.profileDataSets 		= [primaryDataSet]
        self.profileSeriesType      = seriesType
		self.rangeChangedHandler	= handler
		self.highlightRange			= nil
	}
	
	mutating func addDataSet(_ dataSet : ViewProfileDataSet) {
		guard dataSet.profileDisplayType != .primary else {
			appLog.error("Adding primary dataSet")
			return
		}
		self.profileDataSets.append(dataSet)
	}
	
	mutating func removeDataSetsOfDisplayType(_ type : ViewProfileDisplayType) {
		self.profileDataSets.removeAll(where: { $0.profileDisplayType == type })
	}
    
    mutating func removeDataSetForOwner(_ owner : StreamOwner) {
        if let index = self.profileDataSets.firstIndex (where: { $0.streamOwner == owner }) {
            self.profileDataSets.remove(at: index)
        } else {
            appLog.error("Can't remove dataSet for owner \(owner.description)")
        }
    }
    
    var primaryDataSet : ViewProfileDataSet {
        return self.profileDataSets.first!
    }
}

