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

class RVRouteProfileViewController: UIViewController {
	
	// View that is managed by this controller
	
	@IBOutlet private weak var routeView: RVRouteProfileView!
	@IBOutlet private weak var noDataLabel: UILabel!
	@IBOutlet private weak var waitingLabel: UILabel!
	
	// Vertical axis view and labels
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
	
	// Public interface
	func setPrimaryProfile<S> (streamOwner: S, profileType: ViewProfileDataType, range: RouteIndexRange? = nil) -> Bool where S : StreamOwner {
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: streamOwner) {
			profileData	= ViewProfileData(primaryDataSet: ViewProfileDataSet(streamOwner: streamOwner,
																				profileDataType: profileType,
																				profileDisplayType: .primary,
																				dataPoints: dataPoints),
											 									handler: nil )
			self.noDataLabel.isHidden = true
			self.waitingLabel.isHidden = true
			self.routeView.profileData = self.profileData
			self.setAxisLabelsWithData(self.profileData)
			return true
		} else {
			self.routeView.isHidden = true
			self.waitingLabel.isHidden = true
			self.noDataLabel.isHidden = false
			return false
		}
	}
	
	func addProfile<S>(owner : S, profileType: ViewProfileDataType, displayType : ViewProfileDisplayType) where S : StreamOwner {
		guard profileData != nil else {
			appLog.error("No profile to add to")
			return
		}
		
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: owner) {
			profileData.addDataSet(ViewProfileDataSet(streamOwner: owner, profileDataType: profileType, profileDisplayType: displayType, dataPoints: dataPoints))
			self.routeView.profileData = profileData
		}
	}
	
	func removeSecondaryProfiles() {
		if profileData != nil {
			profileData.removeDataSetsOfDisplayType(.secondary)
			self.routeView.profileData = profileData
		}
	}
	
	func setHighLightRange(_ range : RouteIndexRange?) {
		routeView.profileData?.highlightRange = range
	}
	
	// Private functions
	
	private func dataPointsForStreamType<S> (_ profileType : ViewProfileDataType, streamOwner : S) -> [DataPoint]? where S : StreamOwner {
		let streams = streamOwner.streams.map { $0.type! }
		appLog.verbose("Target: \(profileType.stravaValue), streams are \(streams)")
		
		guard let stream = (streamOwner.streams.filter { $0.type == profileType.stravaValue }).first,
			let axis = (streamOwner.streams.filter { $0.type == ViewProfileDataType.distance.stravaValue }).first else {
				appLog.error("Missing target: \(profileType.stravaValue), streams are \(streams)")
				return nil
		}
		
		let axisValues = axis.dataPoints
		let dataPoints = stream.dataPoints.enumerated().map({ DataPoint(dataValue: $0.element, axisValue: axisValues[$0.offset]) })
		appLog.verbose("Returning \(dataPoints.count) points for type \(profileType), axis range \(dataPoints.first!.axisValue) to \(dataPoints.last!.axisValue)")
		return dataPoints
	}
	
	
	private func setAxisLabelsWithData(_ profileData : ViewProfileData) {
		if let primarySet = profileData.dataSetsOfDisplayType(.primary).first {
			let minValue			= primarySet.dataBounds.minY
			let maxValue			= primarySet.dataBounds.maxY
			let midValue			= ((maxValue-minValue) * 0.5 + minValue)
			
			switch primarySet.profileDataType {
			case .heartRate, .power, .altitude:
				vert0Label.text			= minValue.fixedFraction(digits: 0)
				vert50Label.text		= midValue.fixedFraction(digits: 0)
				vert100Label.text		= maxValue.fixedFraction(digits: 0)
			case .speed:
				vert0Label.text			= minValue.speedDisplayString(style: .short, fractionDigits: 0)
				vert50Label.text		= midValue.speedDisplayString(style: .short, fractionDigits: 0)
				vert100Label.text		= maxValue.speedDisplayString(style: .short, fractionDigits: 0)
			default:
				appLog.error("Unsupported profile type \(primarySet.profileDataType)")
			}
			
			let minDistance = 0.0
			let maxDistance = primarySet.dataBounds.maxX - primarySet.dataBounds.minX
			
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
