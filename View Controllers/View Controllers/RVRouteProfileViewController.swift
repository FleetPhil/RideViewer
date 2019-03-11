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
	case altitude
	case heartrate
	case watts
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
}

struct ViewProfileDataSet {
	var profileDataType : ViewProfileDataType
	var profileDisplayType : ViewProfileDisplayType
	var profileDataPoints : [Double]

	func dataPointsInScope(viewRange : RouteIndexRange) -> [(Int, Double)] {
		return self.profileDataPoints.enumerated().filter({ $0.offset >= viewRange.from && $0.offset <= viewRange.to })
	}
	func dataMin(viewRange : RouteIndexRange) -> Double {
		return dataPointsInScope(viewRange: viewRange).reduce(Double.greatestFiniteMagnitude, { min($0, $1.1) })
	}
	func dataMax(viewRange : RouteIndexRange) -> Double {
		return dataPointsInScope(viewRange: viewRange).reduce(0.0, { max($0, $1.1) })
	}
}

struct ViewProfileData {
	private(set) var streamOwner : StreamOwner
	private var profileDataSets: [ViewProfileDataSet]
	private(set) var fullRange : RouteIndexRange
	var viewRange : RouteIndexRange
	var highlightRange: RouteIndexRange?
	private(set) var rangeChangedHandler: ((RouteIndexRange) -> Void)?
	
	init(streamOwner : StreamOwner, handler : ((RouteIndexRange) -> Void)? = nil) {
		self.streamOwner			= streamOwner
		self.profileDataSets 		= []
		self.rangeChangedHandler	= handler
		self.fullRange				= RouteIndexRange(from: 0, to: 0)
		self.viewRange				= self.fullRange
		self.highlightRange			= nil
	}
	
	mutating func addDataSet(_ dataSet : ViewProfileDataSet) {
		self.profileDataSets.append(dataSet)
		self.fullRange				= RouteIndexRange(from: 0, to: (self.profileDataSets.reduce(0) { max($0, $1.profileDataPoints.count) }) - 1)
		self.viewRange				= self.fullRange
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
		CoreDataManager.sharedManager().persistentContainer.performBackgroundTask { [weak self] (context) in
			let asyncActivity = context.object(with: streamOwner.objectID) as! S
			
			self?.profileData = ViewProfileData(streamOwner: streamOwner, handler: nil)
			
			let streams = asyncActivity.streams.map { $0.type! }
			appLog.verbose("Streams are \(streams)")

			if let dataSet = (asyncActivity.streams.filter { $0.type == profileType.stravaValue }).first {
				self?.profileData.addDataSet(ViewProfileDataSet(profileDataType: profileType, profileDisplayType: .primary, profileDataPoints: dataSet.dataPoints))
			}
			// Always include distance set
			if let dataSet = (asyncActivity.streams.filter { $0.type == ViewProfileDataType.distance.stravaValue }).first {
				self?.profileData.addDataSet(ViewProfileDataSet(profileDataType: .distance, profileDisplayType: .axis, profileDataPoints: dataSet.dataPoints))
			}
			
			DispatchQueue.main.async {
				if let `self` = self, self.profileData.dataSetCount >= 2 {
					self.noDataLabel.isHidden = true
					self.waitingLabel.isHidden = true
					self.routeView.profileData = self.profileData
					self.setAxisLabelsWithData(self.profileData, forType: profileType)
				} else {
					self?.waitingLabel.isHidden = true
					self?.noDataLabel.isHidden = false
				}
			}
		}
	}
	
	func addSecondaryProfile(profileType: ViewProfileDataType) {
		if let dataSet = (profileData?.streamOwner.streams.filter { $0.type == profileType.stravaValue })?.first {
			profileData.addDataSet(ViewProfileDataSet(profileDataType: profileType, profileDisplayType: .secondary, profileDataPoints: dataSet.dataPoints))
		}
	}
	
	func setHighLightRange(_ range : RouteIndexRange?) {
		routeView.profileData?.highlightRange = range
	}
	
	private func setAxisLabelsWithData(_ profileData : ViewProfileData, forType : ViewProfileDataType) {
		// Horizontal axis is distance, vertical is selected data type
		guard let distanceProfileSet = profileData.dataSetOfDisplayType(.axis) else { return }
		guard let targetProfileSet = profileData.dataSetOfDataType(forType) else { return }
		
		let minDistance = distanceProfileSet.dataMin(viewRange: profileData.fullRange)
		let maxDistance = distanceProfileSet.dataMax(viewRange: profileData.fullRange)
		
		horiz0Label.text		= minDistance.distanceDisplayString
		horiz25Label.text		= ((maxDistance-minDistance)*0.25 + minDistance).distanceDisplayString
		horiz50Label.text		= ((maxDistance-minDistance)*0.5 + minDistance).distanceDisplayString
		horiz75Label.text		= ((maxDistance-minDistance)*0.75 + minDistance).distanceDisplayString
		horiz100Label.text		= ((maxDistance-minDistance) + minDistance).distanceDisplayString

		let minValue			= targetProfileSet.dataMin(viewRange: profileData.fullRange)
		let maxValue			= targetProfileSet.dataMax(viewRange: profileData.fullRange)
		
		vert0Label.text			= minValue.fixedFraction(digits: 0)
		vert50Label.text		= ((maxValue-minValue)*0.5 + minValue).fixedFraction(digits: 0)
		vert100Label.text		= ((maxValue-minValue) + minValue).fixedFraction(digits: 0)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		routeView.setNeedsDisplay()
	}
}
