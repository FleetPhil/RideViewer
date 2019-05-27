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
	private var profileData : ViewProfileData?
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
	*/
    func setPrimaryProfile<S> (streamOwner: S, profileType: RVStreamDataType, seriesType: RVStreamDataType) where S : StreamOwner {
        // TODO: use .distance or .time as appropriate
        streamOwner.dataPointsForStreamType(profileType, seriesType: seriesType, completionHandler: { [weak self] dataPoints in
            guard let `self` = self else { return }     // Out of scope
            
            guard let dataPoints = dataPoints else {
                appLog.error("Failed to get data points of type \(profileType)")
                self.profileChartView.noDataText = "Unable to get data of type \(profileType.stringValue)"
                self.profileData = nil
                return
            }
            
            // Create the data set with the required stream
            let dataSet = ViewProfileDataSet(streamOwner: streamOwner,
                                             profileDataType: profileType,
                                             profileDisplayType: .primary,
                                             dataPoints: dataPoints)
            
            self.profileData    = ViewProfileData(primaryDataSet: dataSet, seriesType: seriesType)
            
            // Calculate the number of data points to display, create the line chart data set and assign to the chart view
            self.countOfPointsToDisplay = Int(self.profileChartView.bounds.width / DisplayConstants.ScreenPointsPerDataPoint)
            let primarySet = self.chartDataSet(dataSet, displayDataPoints: self.countOfPointsToDisplay)
            self.profileChartView.data = LineChartData(dataSets: [primarySet])
            self.profileChartView.leftAxis.valueFormatter = profileType.chartValueFormatter
        })
	}
	
	
	/**
	Add an additional profile for this view
	
	- Parameters:
		- streamOwner: NSManagedObject owner of the stream conforming to the StreamOwner protocol
		- profileType: type of data to be shown in the profile
		- displayType: how the data should be displayed
	
	- Returns: None
	*/
    func addProfile<S>(streamOwner : S, profileType: RVStreamDataType, displayType : ViewProfileDisplayType, withRange : RouteIndexRange?) where S : StreamOwner {
		guard profileData != nil else {
			appLog.error("No profile to add to")
			return
		}
        
        streamOwner.dataPointsForStreamType(profileType, seriesType: profileData!.profileSeriesType, completionHandler: { [weak self] dataPoints in
            guard let `self` = self else { return }     // Out of scope
            
            guard let dataPoints = dataPoints else {
                appLog.error("Failed to add data points of type \(profileType)")
                return
            }

            let dataSet = ViewProfileDataSet(streamOwner: streamOwner, profileDataType: profileType, profileDisplayType: displayType, dataPoints: dataPoints)
            self.profileData!.addDataSet(dataSet)
            self.profileChartView.data?.addDataSet(self.chartDataSet(dataSet, displayDataPoints: self.countOfPointsToDisplay))
            self.profileChartView.notifyDataSetChanged()
        })
	}
	
	/**
	Remove all secondary profiles
	*/
	func removeSecondaryProfiles() {
		if profileData != nil {
			profileData!.removeDataSetsOfDisplayType(.secondary)
		}
        self.profileChartView.notifyDataSetChanged()
	}
	
	/**
	Highlight a range of values

	- Parameters:
		- range: range to be highlighted (in x axis units). nil to remove highlights
	*/
	func setHighLightRange(_ range : RouteIndexRange?) {
		if range == nil {
			profileChartView.xAxis.removeAllLimitLines()
		} else {
			let lowLimit = ChartLimitLine(limit: range!.from)
			lowLimit.lineColor = DisplayConstants.LimitLineColour
			profileChartView.xAxis.addLimitLine(lowLimit)

			let highLimit = ChartLimitLine(limit: range!.to)
			highLimit.lineColor = DisplayConstants.LimitLineColour
			profileChartView.xAxis.addLimitLine(highLimit)
			
			profileChartView.notifyDataSetChanged()
		}
	}
	
	// Private functions
	
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
			lineDataSet.setColor(DisplayConstants.PrimaryProfileColour, alpha: 1.0)
		case .secondary:
			lineDataSet.setColor(DisplayConstants.SecondaryProfileColour, alpha: 1.0)
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




