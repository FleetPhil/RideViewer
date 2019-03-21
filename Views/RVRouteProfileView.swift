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
	private func plot(rect : CGRect, x : Double, y: Double, bounds : DataBounds) -> CGPoint? {
		guard y>=bounds.minY, y<=bounds.maxY, x>=bounds.minX else {
			appLog.error("Error: data point to plot out of bounds")
			return nil
		}
		
		if x>bounds.maxX {
			// Axis value greater than the primary axis, ignore as should only be a few points
			appLog.verbose("X value exceeds axis by \(x - bounds.maxX) (\(x), \(bounds.maxX))")
			return nil
		}
		
		let scaledX = (x - bounds.minX)/(bounds.maxX - bounds.minX)
		let scaledY = (y - bounds.minY)/(bounds.maxY - bounds.minY)
		
		let newX = CGFloat(scaledX) * rect.width + rect.minX
		let newY = rect.maxY - CGFloat(scaledY) * rect.height
		
		return CGPoint(x: newX, y: newY)
	}
	
	private func plotValues(rect : CGRect, dataValues : [DataPoint], dataBounds : DataBounds) -> [CGPoint] {
		// Calculate the offset of the start of the x axis from the x axis of the primary set and use it as an adjustment for each of the x values
		let xOffset = dataValues[0].axisValue - dataBounds.minX
		
		let points = dataValues.enumerated().compactMap {
			plot(rect: rect, x: dataValues[$0.offset].axisValue - xOffset, y: dataValues[$0.offset].dataValue, bounds: dataBounds)
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
		guard profileData != nil else { return }
		
		self.backgroundColor = UIColor.white
		
		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}
		
		appLog.verbose("Draw: \(profileData!.profileDataSets.map { ($0.profileDataType, $0.profileDisplayType) })")
		
		let viewRange = profileData!.viewRange
		
		for dataSet in profileData!.profileDataSets {
			appLog.verbose("Draw set: \(dataSet.profileDataType), \(dataSet.profileDisplayType), \(dataSet.dataPoints.count) values")

			switch dataSet.profileDisplayType {
			
			case .primary, .secondary:
				// Primary and secondary draw as a line with data bounds set by primary
				let pointsToDraw = plotValues(rect: self.bounds, dataValues: dataSet.dataPoints, dataBounds: profileData!.mainDataBounds)
				let path = UIBezierPath()
				path.lineWidth = 1.0
				path.move(to: pointsToDraw[0])
				for i in 1..<pointsToDraw.count {
					path.addLine(to: pointsToDraw[i])
				}
				dataSet.profileDisplayType.displayColour.setStroke()
				path.stroke()
			
			case .background:
				// Background draws as a shaded background
				// Data bounds for the background are relative to the background bounds, not the primary
				
				let dataBounds = dataSet.dataBounds(viewRange: viewRange)
				let viewBounds = CGRect(x: 0, y: self.bounds.height * 0.25 , width: self.bounds.width, height: self.bounds.height * 0.75 )
				let pointsToDraw = plotValues(rect: viewBounds, dataValues: dataSet.dataPoints, dataBounds: dataBounds)

				let path = UIBezierPath()
				path.move(to: pointsToDraw[0])
				for i in 1..<pointsToDraw.count {
					path.addLine(to: pointsToDraw[i])
				}
				path.addLine(to: CGPoint(x: pointsToDraw.last!.x, y: self.bounds.maxY))
				path.addLine(to: CGPoint(x: pointsToDraw[0].x, y: self.bounds.maxY))
				path.addLine(to: pointsToDraw[0])
				UIColor.init(displayP3Red: 1.0, green: 0, blue: 0, alpha: 0.3).setFill()
				path.fill()
			}
		}
	}
}

