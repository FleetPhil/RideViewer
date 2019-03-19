//
//  RVRouteProfileViewController.swift
//  RideViewer
//
//  Created by Home on 01/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//


//  This controller manages an RVRouteProfileView

import UIKit
import CoreData

// Class objects that own streams adopt this protocol
protocol StreamOwner where Self : NSManagedObject {
	var streams: Set<RVStream> { get }
}

extension StreamOwner {
	func hasStreamOfType(_ type : ViewProfileDataType) -> Bool {
		return self.streams.filter({ $0.type == type.stravaValue }).first != nil
	}
}


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
	case axis
	case background
	
	var displayColour : UIColor {
		switch self {
		case .primary:		return UIColor.black
		case .secondary:	return UIColor.green
		case .axis:			return UIColor.black
		case .background:	return UIColor.lightGray
		}
	}
}

struct DataPoint {
	var dataValue : Double
	var axisValue : Double
}

// Max / min for the dataSet to be plotted
struct PlotBounds {
	var minX : Double
	var maxX : Double
	var minY : Double
	var maxY : Double
}

struct ViewProfileDataSet {
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
	private(set) var streamOwner : StreamOwner
	private(set) var profileDataSets: [ViewProfileDataSet]
	private var plotBounds: PlotBounds
	var viewRange : RouteIndexRange = RouteIndexRange(from: 0, to: 0)		// Referenced to the primary dataSet
	var highlightRange: RouteIndexRange?									// Referenced to the primary dataSet
	private(set) var rangeChangedHandler: ((RouteIndexRange) -> Void)?
	
	// TODO: should init with the primary set
	init(streamOwner : StreamOwner, handler : ((RouteIndexRange) -> Void)? = nil) {
		self.streamOwner			= streamOwner
		self.profileDataSets 		= []
		self.rangeChangedHandler	= handler
		self.highlightRange			= nil
		self.plotBounds				= PlotBounds(minX: 0, maxX: 0, minY: 0, maxY: 0)
	}
	
	mutating func addDataSet(_ dataSet : ViewProfileDataSet) {
		self.profileDataSets.append(dataSet)
		if dataSet.profileDisplayType == .primary {
			self.viewRange = dataSet.fullRange
		}
		// Set the bounds of all the data sets
		
	}
	
	func dataSetOfDataType(_ dataType : ViewProfileDataType) -> ViewProfileDataSet? {
		return self.profileDataSets.filter({ $0.profileDataType == dataType }).first
	}
	func dataSetOfDisplayType(_ displayType : ViewProfileDisplayType) -> ViewProfileDataSet? {
		return self.profileDataSets.filter({ $0.profileDisplayType == displayType }).first
	}
	
	var dataSetCount : Int {
		return profileDataSets.count
	}
}

class RVRouteProfileViewController: UIViewController {
	
	// View that is managed by this controller
	@IBOutlet private weak var routeView: RVRouteProfileView!
	@IBOutlet private weak var noDataLabel: UILabel!
	@IBOutlet private weak var waitingLabel: UILabel!
	
	// Vertical axis labels
	@IBOutlet private weak var vert0Label: UILabel!
	@IBOutlet private weak var vert50Label: UILabel!
	@IBOutlet private weak var vert100Label: UILabel!
	
	// Horizontal Axis Labels
	@IBOutlet private weak var horiz0Label: UILabel!
	@IBOutlet private weak var horiz25Label: UILabel!
	@IBOutlet private weak var horiz50Label: UILabel!
	@IBOutlet private weak var horiz75Label: UILabel!
	@IBOutlet private weak var horiz100Label: UILabel!
	
	var viewRange : RouteIndexRange?
	
	// Properties
	private var profileData : ViewProfileData!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	func setPrimaryProfile<S> (streamOwner: S, profileType: ViewProfileDataType, range: RouteIndexRange? = nil) where S : StreamOwner {
		profileData = ViewProfileData(streamOwner: streamOwner, handler: nil)
		
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: streamOwner) {
			profileData.addDataSet(ViewProfileDataSet(profileDataType: profileType, profileDisplayType: .primary, dataPoints: dataPoints))
			
			self.noDataLabel.isHidden = true
			self.waitingLabel.isHidden = true
			self.routeView.profileData = self.profileData
			self.setAxisLabelsWithData(self.profileData)
		} else {
			self.waitingLabel.isHidden = true
			self.noDataLabel.isHidden = false
		}
	}
	
	func dataPointsForStreamType<S> (_ profileType : ViewProfileDataType, streamOwner : S) -> [DataPoint]? where S : StreamOwner {
		let streams = streamOwner.streams.map { $0.type! }
		appLog.verbose("Target: \(profileType.stravaValue), streams are \(streams)")
		
		guard let stream = (streamOwner.streams.filter { $0.type == profileType.stravaValue }).first,
			let axis = (streamOwner.streams.filter { $0.type == ViewProfileDataType.distance.stravaValue }).first else {
				appLog.error("Missing target: \(profileType.stravaValue), streams are \(streams)")
				return nil
		}
		
		let axisValues = axis.dataPoints
		let dataPoints = stream.dataPoints.enumerated().map({ DataPoint(dataValue: $0.element, axisValue: axisValues[$0.offset]) })
		appLog.verbose("Returning \(dataPoints.count) data points for stream type \(profileType)")
		return dataPoints
	}
	
	func addSecondaryProfile<S>(owner : S, profileType: ViewProfileDataType) where S : StreamOwner {
		// Return if no primary
		guard profileData.dataSetOfDisplayType(.primary) != nil else {
			appLog.debug("No primary for secondary \(profileType)")
			return
		}
		
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: owner) {
			profileData.addDataSet(ViewProfileDataSet(profileDataType: profileType, profileDisplayType: .secondary, dataPoints: dataPoints))
			self.routeView.profileData = profileData
		}
	}
	
	func removeSecondaryProfile<S>(owner: S) where S : StreamOwner {
//		let x = profileData.profileDataSets.filter({ $0. })
	}
	
	func setHighLightRange(_ range : RouteIndexRange?) {
		routeView.profileData?.highlightRange = range
	}
	
	private func setAxisLabelsWithData(_ profileData : ViewProfileData) {
		if let primarySet = profileData.dataSetOfDisplayType(.primary) {
			let minValue			= primarySet.dataMin(viewRange: primarySet.fullRange)
			let maxValue			= primarySet.dataMax(viewRange: primarySet.fullRange)
			
			vert0Label.text			= minValue.fixedFraction(digits: 0)
			vert50Label.text		= ((maxValue-minValue) * 0.5 + minValue).fixedFraction(digits: 0)
			vert100Label.text		= ((maxValue-minValue) + minValue).fixedFraction(digits: 0)
			
			let minDistance = 0.0
			let maxDistance = primarySet.fullRange.to - primarySet.fullRange.from
			
			horiz0Label.text		= minDistance.distanceDisplayString
			horiz25Label.text		= ((maxDistance-minDistance) * 0.25 + minDistance).distanceDisplayString
			horiz50Label.text		= ((maxDistance-minDistance) * 0.5 + minDistance).distanceDisplayString
			horiz75Label.text		= ((maxDistance-minDistance) * 0.75 + minDistance).distanceDisplayString
			horiz100Label.text		= ((maxDistance-minDistance) + minDistance).distanceDisplayString
		}
	}
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		routeView.setNeedsDisplay()
	}
}
