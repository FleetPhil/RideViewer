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
		self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(didPinch)))
		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
		self.isUserInteractionEnabled = true
	}
	
	@IBAction func didPinch(_ gestureRecognizer : UIPinchGestureRecognizer) {
		guard gestureRecognizer.view != nil, profileData != nil else { return }
		
		// NOTE: if profileData is set then data ranges are too
		
		if gestureRecognizer.state == .ended {
			if let handler = profileData?.rangeChangedHandler {
				handler(profileData!.viewRange)
			}
		}
		
		guard gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
		
		let visiblePoints = CGFloat(profileData!.viewRange.to - profileData!.viewRange.from)
		let newVisiblePoints = CGFloat(profileData!.viewRange.to - profileData!.viewRange.from) / gestureRecognizer.scale
		let change = Int(newVisiblePoints - visiblePoints)
		profileData!.viewRange = RouteIndexRange(from: profileData!.viewRange.from - change/2, to: profileData!.viewRange.to + change/2)
		if profileData!.viewRange.from < 0 {
			profileData!.viewRange.to += -profileData!.viewRange.from
			profileData!.viewRange.from += -profileData!.viewRange.from
		}
		if Int(newVisiblePoints) > profileData!.fullRange.to {
			profileData!.viewRange = RouteIndexRange(from: 0, to: profileData!.fullRange.to)
		}
		gestureRecognizer.scale = 1.0
		self.setNeedsDisplay()
	}
	
	@IBAction func didPan(_ gestureRecognizer : UIPanGestureRecognizer) {
		guard gestureRecognizer.view != nil, profileData != nil else { return }
		
		switch gestureRecognizer.state {
		case .ended:
			if let handler = profileData?.rangeChangedHandler {
				handler(profileData!.viewRange)
			}
		case .began, .changed:
			let widthPerDataPoint = self.bounds.width / CGFloat(profileData!.viewRange.to - profileData!.viewRange.from)
			profileData!.viewRange.from -= Int(gestureRecognizer.translation(in: self).x / widthPerDataPoint)
			
			if profileData!.viewRange.from < 0 { profileData!.viewRange.from = 0 }
			
			profileData!.viewRange.to = profileData!.viewRange.from + Int(self.bounds.width / widthPerDataPoint)
			if profileData!.viewRange.to > profileData!.fullRange.to {
				profileData!.viewRange.from -= (profileData!.viewRange.to - profileData!.fullRange.to)
				profileData!.viewRange.to -= (profileData!.viewRange.to - profileData!.fullRange.to)
			}
			gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)
			self.setNeedsDisplay()
		default:
			break
			
		}
	}
	
	private func pathForDataSet(_ dataSet: ViewProfileDataSet) -> UIBezierPath? {
		guard profileData != nil else { return nil }
		guard profileData!.fullRange.to > 0, profileData!.viewRange.to - profileData!.viewRange.from > 0 else { return nil }
		
		let yInset = self.bounds.height / 10
		
		let widthPerDataPoint = self.bounds.width / CGFloat(profileData!.viewRange.to - profileData!.viewRange.from)
		let dataMin = dataSet.dataMin(viewRange: profileData!.viewRange)
		let dataMax = dataSet.dataMax(viewRange: profileData!.viewRange)
		let dataRange = max(dataMax-dataMin, 1.0)
		
		func pointForData(_ data : Double, index : Int) -> CGPoint {
			let x = CGFloat(index) * widthPerDataPoint
			let y = self.bounds.height - (((CGFloat((data-dataMin) / dataRange)) * (self.bounds.height-yInset)) + yInset/2)
			return CGPoint(x: x, y: y)
		}
		
		let path = UIBezierPath()
		for (index, point) in dataSet.profileDataPoints.enumerated() {
			if index == profileData!.viewRange.from {
				path.move(to: pointForData(point, index: 0))
			} else if index > profileData!.viewRange.from {
				if path.currentPoint == CGPoint.zero {
					appLog.severe("no current point")
					fatalError()
				}
				path.addLine(to: pointForData(point, index: index-profileData!.viewRange.from))
			}
		}
		
		return path
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
		// TODO: draw multiple data sets
		self.backgroundColor = UIColor.white

		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}

		appLog.verbose {
			let dataSets = profileData?.profileDataSets.map { ($0.profileDataType, $0.profileDisplayType) } ?? []
			return "Draw: \(dataSets)"
		}
		for dataSet in profileData?.profileDataSets ?? [] {
			if dataSet.profileDisplayType != .axis {
				if let path = pathForDataSet(dataSet) {
					path.lineWidth = 1.0
					dataSet.profileDisplayType.displayColour.setStroke()
					path.stroke()
				}
			}
		}
	}
}

