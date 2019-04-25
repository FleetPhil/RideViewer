//
//  Chart Utilities.swift
//  RideViewer
//
//  Created by Home on 25/04/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import Charts

class AxisValueFormatter: NSObject, IAxisValueFormatter {
	fileprivate var numberFormatter: ((Double)->String)?
	
	convenience init(numberFormatter: @escaping (Double)->String) {
		self.init()
		self.numberFormatter = numberFormatter
	}
	
	func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		guard let numberFormatter = numberFormatter
			else {
				return ""
		}
		return numberFormatter(value)
	}
}
