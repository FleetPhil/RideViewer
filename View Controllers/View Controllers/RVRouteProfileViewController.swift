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
import StravaSwift


// Class objects that own streams adopt this protocol
protocol StreamOwner where Self : NSManagedObject {
	var streams: Set<RVStream> { get }
}

// Data structures for the view
enum ViewProfileDataType : String {
	case altitude
	case heartrate
	case watts
	case distance
	case cadence
}

struct ViewProfileDataSet {
	var profileDataType : ViewProfileDataType
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
	private var profileDataSets: [ViewProfileDataSet]
	private(set) var fullRange : RouteIndexRange
	var viewRange : RouteIndexRange
	var highlightRange: RouteIndexRange?
	private(set) var rangeChangedHandler: ((RouteIndexRange) -> Void)?
	
	init(handler : ((RouteIndexRange) -> Void)? = nil) {
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
	
	func dataSetOfType(_ dataType : ViewProfileDataType) -> ViewProfileDataSet? {
		return self.profileDataSets.filter({ $0.profileDataType == dataType }).first
	}
}

class RVRouteProfileViewController: UIViewController {
	
	// View that is managed by this controller
	@IBOutlet weak var routeView: RVRouteProfileView!
	
	// Vertical axis labels
	@IBOutlet weak var vert0Label: UILabel!
	@IBOutlet weak var vert50Label: UILabel!
	@IBOutlet weak var vert100Label: UILabel!
	
	// Horizontal Axis Labels
	@IBOutlet weak var horiz0Label: UILabel!
	@IBOutlet weak var horiz25Label: UILabel!
	@IBOutlet weak var horiz50Label: UILabel!
	@IBOutlet weak var horiz75Label: UILabel!
	@IBOutlet weak var horiz100Label: UILabel!
	
	// Model - a NSManagedObject that has a 'streams' var
	var streamOwner : StreamOwner!
	var viewRange : RouteIndexRange?
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
	func setProfile<S> (streamOwner: S, profileType: StravaSwift.StreamType, range: RouteIndexRange? = nil) where S : StreamOwner {
		CoreDataManager.sharedManager().persistentContainer.performBackgroundTask { [weak self] (context) in
			let asyncActivity = context.object(with: streamOwner.objectID) as! S
			
			var profileData = ViewProfileData(handler: nil)
			
			let streams = asyncActivity.streams.map { $0.type! }
			appLog.debug("Streams are \(streams)")

			if let dataSet = self?.profileDataSet(forOwner: asyncActivity, ofType: profileType) {
				profileData.addDataSet(dataSet)
			} else {
				appLog.debug("Failed to find data stream type \(profileType)")
			}
			// Always include distance set
			if let distanceDataSet = self?.profileDataSet(forOwner: asyncActivity, ofType: .distance) {
				profileData.addDataSet(distanceDataSet)
			}
			
			DispatchQueue.main.async {
				self?.routeView.profileData = profileData
				self?.setAxisLabelsWithData(profileData, forType: ViewProfileDataType.altitude)
			}
		}
	}
	
	private func setAxisLabelsWithData(_ profileData : ViewProfileData, forType : ViewProfileDataType) {
		// Horizontal axis is distance, vertical is selected data type
		guard let distanceProfileSet = profileData.dataSetOfType(.distance) else { return }
		guard let targetProfileSet = profileData.dataSetOfType(forType) else { return }
		
		let minDistance = distanceProfileSet.dataMin(viewRange: profileData.fullRange)
		let maxDistance = distanceProfileSet.dataMax(viewRange: profileData.fullRange)
		appLog.debug("Distance axis from \(minDistance) to \(maxDistance)")
		
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
	
	private func profileDataSet<S>(forOwner owner : S, ofType: StravaSwift.StreamType) -> ViewProfileDataSet? where S : StreamOwner {
		if let stream = (owner.streams.filter { $0.type == ofType.rawValue }).first {
			let dataStream = stream.dataPoints.sorted(by: { $0.index < $1.index }).map({ $0.dataPoint })
			return ViewProfileDataSet(profileDataType: ViewProfileDataType(rawValue: ofType.rawValue)!, profileDataPoints: dataStream )
		} else {
			return nil
		}
	}
}
