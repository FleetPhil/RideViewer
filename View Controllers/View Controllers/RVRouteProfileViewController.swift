//
//  RVRouteProfileViewController.swift
//  RideViewer
//
//  Created by Home on 01/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//


///  This controller manages an RVRouteProfileView

import UIKit
import CoreData
import Charts

class RVRouteProfileViewController: UIViewController {
	// Model
	
	/// Struct with the data to be shown
	private var profileData : ViewProfileData!
	private var countOfPointsToDisplay : Int = 0
	
	/// View that is managed by this controller
	@IBOutlet weak var profileChartView: RVRouteProfileView!
	
	// Public interface
	/**
	Set the main profile for this view - determines the type of data that is shown, the number of data points and the formatting of the left axis
	
	- Parameters:
		- streamOwner: NSManagedObject owner of the stream conforming to the StreamOwner protocol
		- profileType: type of data to be shown in the profile
		- range: unused?

	- Returns: Bool indicating success (TODO: should throw if error)
	
	- ToDo: remove range
	*/
	func setPrimaryProfile<S> (streamOwner: S, profileType: RVStreamDataType, range: RouteIndexRange? = nil) -> Bool where S : StreamOwner {
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: streamOwner) {
			// Create the data set with the required stream
			let dataSet = ViewProfileDataSet(streamOwner: streamOwner,
											 profileDataType: profileType,
											 profileDisplayType: .primary,
											 dataPoints: dataPoints)

			profileData	= ViewProfileData(primaryDataSet: dataSet)
			
			// Calculate the number of data points to display, create the line chart data set and assign to the chart view
			countOfPointsToDisplay = Int(profileChartView.bounds.width / DisplayConstants.ScreenPointsPerDataPoint)
			let primarySet = chartDataSet(dataSet, displayDataPoints: countOfPointsToDisplay)
			profileChartView.data = LineChartData(dataSets: [primarySet])
			profileChartView.leftAxis.valueFormatter = profileType.chartValueFormatter
			return true
		} else {
			return false
		}
	}
	
	
	/**
	Add an additional profile for this view
	
	- Parameters:
		- streamOwner: NSManagedObject owner of the stream conforming to the StreamOwner protocol
		- profileType: type of data to be shown in the profile
		- displayType: how the data should be displayed
	
	- Returns: None
	*/
	func addProfile<S>(streamOwner : S, profileType: RVStreamDataType, displayType : ViewProfileDisplayType) where S : StreamOwner {
		guard profileData != nil else {
			appLog.error("No profile to add to")
			return
		}
		
		if let dataPoints = dataPointsForStreamType(profileType, streamOwner: streamOwner) {
			let dataSet = ViewProfileDataSet(streamOwner: streamOwner, profileDataType: profileType, profileDisplayType: displayType, dataPoints: dataPoints)
			profileData.addDataSet(dataSet)
			profileChartView.data?.addDataSet(chartDataSet(dataSet, displayDataPoints: countOfPointsToDisplay))
			profileChartView.notifyDataSetChanged()
		}
	}
	
	/**
	Remove all secondary profiles
	*/
	func removeSecondaryProfiles() {
		if profileData != nil {
			profileData.removeDataSetsOfDisplayType(.secondary)
			
		}
	}
	
	/**
	Highlight a range of values

	Parameter range: tange to be highlighted (in x axis units)
	*/
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
			
			// If type is gear ratio adjust for wheel circumference and main sprocket
			if profileType == .gearRatio {
				return dataPoints.compactMap({ DataPoint(data: rearTeeth(gearRatio: $0.dataValue), axis: $0.axisValue) })
			} else {
				return dataPoints
			}
		}
		return nil
	}
	
	/// Return the implied number of rear teeth based on the small chainring and the speed/cadence parameter
	private func rearTeeth(gearRatio : Double) -> Double? {
		if gearRatio == 0 { return nil }
		let x = (Double(BikeConstants.InnerChainRing)*(Double(BikeConstants.Circumference)/1000.0))/(gearRatio*60.0)
		return x
	}

	
	// Create a Line Chart dataSet from the data points and display type
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
			profileChartView.rightAxis.valueFormatter = dataSet.profileDataType.chartValueFormatter
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




