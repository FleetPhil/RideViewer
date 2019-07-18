//
//  RVRouteProfileView.swift
//  RideViewer
//
//  Created by Home on 04/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit
import Charts

class RVRouteProfileView : LineChartView {
	
	// Set default parameters for the profile chart
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupChart()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupChart()
	}
	
	func setupChart() {
		self.getAxis(.right).enabled = false
		self.getAxis(.left).labelCount = 3
		self.xAxis.labelPosition = .bottom
		self.xAxis.drawGridLinesEnabled = false
		self.xAxis.valueFormatter = self
		self.legend.enabled = false
        self.noDataText = "Waiting for data..."

	}
    
    func setProfileData(_ profileData : ViewProfileData) {
        // Calculate the number of data points to display
        let countOfPointsToDisplay = Int(self.bounds.width / DisplayConstants.ScreenPointsPerDataPoint)

        // Set the left axis format from the primary type
        leftAxis.valueFormatter = profileData.primaryDataSet.profileDataType.chartValueFormatter
        
        //  Map the data sets into line chart data sets
        self.data = LineChartData(dataSets: profileData.profileDataSets
            .filter({ dataSet in dataSet.profileDisplayType != .notShown })
            .map({ dataSet in lineChartDataSet(dataSet, displayDataPoints: countOfPointsToDisplay) }))
    }
    
    /**
     Highlight a range of values
     
     - Parameters:
     - range: range to be highlighted (in x axis units). nil to remove highlights
     */
    func setHighLightRange(_ range : RouteIndexRange?) {
        if range == nil {
            self.xAxis.removeAllLimitLines()
        } else {
            let lowLimit = ChartLimitLine(limit: range!.from)
            lowLimit.lineColor = DisplayConstants.LimitLineColour
            self.xAxis.addLimitLine(lowLimit)
            
            let highLimit = ChartLimitLine(limit: range!.to)
            highLimit.lineColor = DisplayConstants.LimitLineColour
            self.xAxis.addLimitLine(highLimit)
            
            self.notifyDataSetChanged()
        }
    }

    
    // Create a Line Chart dataSet from the data points and display type
    private func lineChartDataSet(_ dataSet : ViewProfileDataSet, displayDataPoints: Int) -> LineChartDataSet {
        var scaleFactor = dataSet.dataPoints.count / displayDataPoints
        if scaleFactor == 0 { scaleFactor = 1 }            // Cannot be zero
        
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
            self.rightAxis.enabled = true
            self.rightAxis.drawGridLinesEnabled = false
            self.rightAxis.valueFormatter = dataSet.profileDataType.chartValueFormatter
            lineDataSet.axisDependency = .right
            
            let colorTop = UIColor(red: 255.0/255.0, green: 94.0/255.0, blue: 58.0/255.0, alpha: 1.0).cgColor
            let colorBottom =  UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0/255.0, alpha: 1.0).cgColor
            
            let gradientColors = [colorTop, colorBottom] as CFArray
            let colorLocations:[CGFloat] = [0.0, 1.0]
            let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) // Gradient Object
            lineDataSet.fill = Fill.fillWithLinearGradient(gradient!, angle: 90.0)
            lineDataSet.drawFilledEnabled = true
            lineDataSet.lineWidth = 0.0
        case .notShown:             // not shown on chart, should not get here
            appLog.error("Not shown??")
            break
        }
        return lineDataSet
    }

}

extension RVRouteProfileView : IAxisValueFormatter {
	func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		return value.distanceDisplayString
	}
}
