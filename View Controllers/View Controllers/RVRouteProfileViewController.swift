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
import Charts

// Delegate is notified when zoom or scroll changes
protocol RVRouteProfileScrollViewDelegate {
    func didChangeScale(viewController : UIViewController, newScale: CGFloat, withOffset: CGPoint)
	func didEndScrolling(viewController : UIViewController, newOffset : CGPoint)
    func didScroll(viewController : UIViewController, newOffset : CGPoint)
}

class RVRouteProfileViewController: UIViewController {
	// Model
	private var profileData : ViewProfileData!
	private var countOfPointsToDisplay : Int = 0
	
	// Delegate
	var delegate : RVRouteProfileScrollViewDelegate?
	
	// View that is managed by this controller
	@IBOutlet weak var profileChartView: RVRouteProfileView!
	
	// Public interface
	func setPrimaryProfile<S> (streamOwner: S, profileType: RVStreamDataType, range: RouteIndexRange? = nil) -> Bool where S : StreamOwner {
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: streamOwner) {
			let dataSet = ViewProfileDataSet(streamOwner: streamOwner,
											 profileDataType: profileType,
											 profileDisplayType: .primary,
											 dataPoints: dataPoints)
			profileData	= ViewProfileData(primaryDataSet: dataSet)
			countOfPointsToDisplay = Int(profileChartView.bounds.width / 2)
			let primarySet = chartDataSet(dataSet, displayDataPoints: countOfPointsToDisplay)
			profileChartView.data = LineChartData(dataSets: [primarySet])
			return true
		} else {
			return false
		}
	}
	
	func addProfile<S>(owner : S, profileType: RVStreamDataType, displayType : ViewProfileDisplayType) where S : StreamOwner {
		guard profileData != nil else {
			appLog.error("No profile to add to")
			return
		}
		
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: owner) {
			let dataSet = ViewProfileDataSet(streamOwner: owner, profileDataType: profileType, profileDisplayType: displayType, dataPoints: dataPoints)
			profileData.addDataSet(dataSet)
			profileChartView.data?.addDataSet(chartDataSet(dataSet, displayDataPoints: countOfPointsToDisplay))
			profileChartView.notifyDataSetChanged()
		}
	}
	
	func removeSecondaryProfiles() {
		if profileData != nil {
			profileData.removeDataSetsOfDisplayType(.secondary)
			
		}
	}
	
	func setHighLightRange(_ range : RouteIndexRange?) {
//		let highlights = Highlight(
//		profileChartView.highlightValues(<#T##highs: [Highlight]?##[Highlight]?#>)
	}
	
	// Private functions
	
	// Return the data points for the specified data type and owner normalised to start at zero on the axis
	private func dataPointsForStreamType<S> (_ profileType : RVStreamDataType, streamOwner : S) -> [DataPoint]? where S : StreamOwner {
		let streams = streamOwner.streams.map { $0.type }
		appLog.verbose("Target: \(profileType.stringValue), streams are \(streams)")
		
		guard let valueStream = (streamOwner.streams.filter { $0.type == profileType }).first,
			let axisStream = (streamOwner.streams.filter { $0.type == RVStreamDataType.distance }).first else {
				appLog.error("Missing stream data: \(profileType.stringValue), streams are \(streams)")
				return nil
		}

		appLog.verbose("axis: \(axisStream.dataPoints.first!) to \(axisStream.dataPoints.last!)")
		
		if let startAxisValue = axisStream.dataPoints.first {
			// Only unpack the axis stream data points from JSON once (for performance reasons)
			let axisDataPoints = axisStream.dataPoints
			let dataPoints = valueStream.dataPoints.enumerated().map({ DataPoint(dataValue: $0.element, axisValue: axisDataPoints[$0.offset] - startAxisValue) })
			appLog.verbose("Returning \(dataPoints.count) points for type \(profileType), axis range \(dataPoints.first!.axisValue) to \(dataPoints.last!.axisValue)")
			return dataPoints
		}
		return nil
	}
	
	private func chartDataSet(_ dataSet : ViewProfileDataSet, displayDataPoints: Int) -> LineChartDataSet {
		var scaleFactor = dataSet.dataPoints.count / displayDataPoints
		if scaleFactor == 0 { scaleFactor = 1 }			// Cannot be zero
		
		var entries : [ChartDataEntry] = []
		
		for i in stride(from: 0, to: dataSet.dataPoints.count, by: scaleFactor) {
			entries.append(ChartDataEntry(x: dataSet.dataPoints[i].axisValue, y: dataSet.dataPoints[i].dataValue))
		}
		
		appLog.verbose("Plotting \(entries.count) points from \(dataSet.dataPoints.count)")
		
		let lineDataSet = LineChartDataSet(entries: entries, label: "")
		lineDataSet.drawCirclesEnabled = false
		lineDataSet.drawValuesEnabled = false
		
		switch dataSet.profileDisplayType {
		case .primary:
			lineDataSet.setColor(UIColor.black, alpha: 1.0)
		case .secondary:
			lineDataSet.setColor(UIColor.green, alpha: 1.0)
		case .background:
			// Setup the axis
			profileChartView.rightAxis.enabled = true
			profileChartView.rightAxis.drawGridLinesEnabled = false
			lineDataSet.axisDependency = .right
			
			let colorTop = UIColor(red: 255.0/255.0, green: 94.0/255.0, blue: 58.0/255.0, alpha: 1.0).cgColor
			let colorBottom =  UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0/255.0, alpha: 1.0).cgColor
			
			let gradientColors = [colorTop, colorBottom] as CFArray
			let colorLocations:[CGFloat] = [0.0, 1.0]
			let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
			lineDataSet.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
			lineDataSet.drawFilledEnabled = true
			lineDataSet.lineWidth = 0.0
		}
		
		
		return lineDataSet
	}
}




