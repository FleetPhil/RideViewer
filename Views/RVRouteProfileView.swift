//
//  RVRouteProfileView.swift
//  RideViewer
//
//  Created by Home on 04/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

class RVRouteProfileView : UIView {
	
	// Public model
	var profileData: ViewProfileData? {
		didSet {
			setNeedsDisplay()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
//		self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(didPinch)))
//		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
		self.isUserInteractionEnabled = true
	}
	
//	@IBAction func didPinch(_ gestureRecognizer : UIPinchGestureRecognizer) {
//		guard gestureRecognizer.view != nil, profileData != nil else { return }
//
//		// NOTE: if profileData is set then data ranges are too
//
//		if gestureRecognizer.state == .ended {
//			if let handler = profileData?.rangeChangedHandler {
//				handler(profileData!.viewRange)
//			}
//		}
//
//		guard gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
//
//		let visiblePoints = CGFloat(profileData!.viewRange.to - profileData!.viewRange.from)
//		let newVisiblePoints = CGFloat(profileData!.viewRange.to - profileData!.viewRange.from) / gestureRecognizer.scale
//		let change = Int(newVisiblePoints - visiblePoints)
//		profileData!.viewRange = RouteIndexRange(from: profileData!.viewRange.from - change/2, to: profileData!.viewRange.to + change/2)
//		if profileData!.viewRange.from < 0 {
//			profileData!.viewRange.to += -profileData!.viewRange.from
//			profileData!.viewRange.from += -profileData!.viewRange.from
//		}
//		if Int(newVisiblePoints) > profileData!.fullRange.to {
//			profileData!.viewRange = RouteIndexRange(from: 0, to: profileData!.fullRange.to)
//		}
//		gestureRecognizer.scale = 1.0
//		self.setNeedsDisplay()
//	}
//
//	@IBAction func didPan(_ gestureRecognizer : UIPanGestureRecognizer) {
//		guard gestureRecognizer.view != nil, profileData != nil else { return }
//
//		switch gestureRecognizer.state {
//		case .ended:
//			if let handler = profileData?.rangeChangedHandler {
//				handler(profileData!.viewRange)
//			}
//		case .began, .changed:
//			let widthPerDataPoint = self.bounds.width / CGFloat(profileData!.viewRange.to - profileData!.viewRange.from)
//			profileData!.viewRange.from -= Int(gestureRecognizer.translation(in: self).x / widthPerDataPoint)
//
//			if profileData!.viewRange.from < 0 { profileData!.viewRange.from = 0 }
//
//			profileData!.viewRange.to = profileData!.viewRange.from + Int(self.bounds.width / widthPerDataPoint)
//			if profileData!.viewRange.to > profileData!.fullRange.to {
//				profileData!.viewRange.from -= (profileData!.viewRange.to - profileData!.fullRange.to)
//				profileData!.viewRange.to -= (profileData!.viewRange.to - profileData!.fullRange.to)
//			}
//			gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)
//			self.setNeedsDisplay()
//		default:
//			break
//
//		}
//	}
	
	// Return the point in the given CGRect that shows the x and y values scaled to the bounds
	// x and y values are in the frame of the secondary, bounds are in the frame of the primary
	func plot(rect : CGRect, x : Double, y: Double, bounds : PlotBounds) -> CGPoint? {
		guard x>=bounds.minX, x<=bounds.maxX, y>=bounds.minY, y<=bounds.maxY else {
			appLog.error("Error: points to plot out of bounds")
			return nil
		}
		let scaledX = (x - bounds.minX)/(bounds.maxX - bounds.minX)
		let scaledY = (y - bounds.minY)/(bounds.maxY - bounds.minY)
		
		let newX = CGFloat(scaledX) * rect.width + rect.minX
		let newY = rect.maxY - CGFloat(scaledY) * rect.height
		
		return CGPoint(x: newX, y: newY)
	}
	
	func plotValues(rect : CGRect, dataValues : [DataPoint], bounds : PlotBounds) -> [CGPoint] {
		appLog.verbose("Plotting \(dataValues.count) values")
		
		// Calculate the offset of the start of the x axis from the x axis of the primary set and use it as an adjustment for each of the x values
		let xOffset = dataValues[0].axisValue - bounds.minX
		
		let points = dataValues.enumerated().compactMap {
			plot(rect: rect, x: dataValues[$0.offset].axisValue - xOffset, y: dataValues[$0.offset].dataValue, bounds: bounds)
		}
		return points
	}
	
	private func createHighlight() -> UIBezierPath? {
		guard let highlight = profileData?.highlightRange, profileData!.viewRange.to - profileData!.viewRange.from > 0 else { return nil }
		
		let widthPerDataPoint = self.bounds.width / CGFloat(profileData!.viewRange.to - profileData!.viewRange.from)
		
		let rect = CGRect(x:( CGFloat(highlight.from) - CGFloat(profileData!.viewRange.from)) * widthPerDataPoint, y: 0,
						  width: CGFloat(highlight.to - highlight.from) * widthPerDataPoint, height: self.bounds.height)
		
		let path = UIBezierPath(rect: rect)
		return path
	}
	
	override func draw(_ rect: CGRect) {
		guard let primaryDataSet = profileData?.dataSetOfDisplayType(.primary) else {
			appLog.debug("No promary dataSet")
			return
		}
		
		self.backgroundColor = UIColor.white
		
		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}
		
		appLog.verbose {
			let dataSets = profileData!.profileDataSets.map { ($0.profileDataType, $0.profileDisplayType) }
			return "Draw: \(dataSets)"
		}
		
		let viewRange = profileData!.viewRange
		let dataBounds = PlotBounds(minX: primaryDataSet.axisMin(viewRange: viewRange),
									maxX: primaryDataSet.axisMax(viewRange: viewRange),
									minY: profileData!.profileDataSets.reduce(Double.greatestFiniteMagnitude, { min($0, $1.dataMin(viewRange: viewRange) ) }),
									maxY: profileData!.profileDataSets.reduce(0.0, { max($0, $1.dataMax(viewRange: viewRange) ) }))
		
		for dataSet in profileData!.profileDataSets {
			appLog.verbose("Draw set: \(dataSet.profileDataType)")
			let pointsToDraw = plotValues(rect: self.bounds, dataValues: dataSet.dataPoints, bounds: dataBounds)
			
			let path = UIBezierPath()
			path.lineWidth = 1.0
			path.move(to: pointsToDraw[0])
			for i in 1..<pointsToDraw.count {
				path.addLine(to: pointsToDraw[i])
			}
			dataSet.profileDisplayType.displayColour.setStroke()
			path.stroke()
		}
	}
}

