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
	}
}

extension RVRouteProfileView : IAxisValueFormatter {
	func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		return value.distanceDisplayString
	}
}
