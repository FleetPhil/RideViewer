//
//  RVRouteProfileView.swift
//  RideViewer
//
//  Created by Home on 04/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

enum ViewProfileDataType {
	case altitude
	case heartRate
	case power
}

struct ViewProfileDataSet {
	var profileDataType : ViewProfileDataType
	var profileDataPoints : [Double]
}

struct ViewProfileData {
	var profileDataSets: [ViewProfileDataSet]
	var highlightRange: RouteIndexRange?
	var rangeChangedHandler: ((RouteIndexRange) -> Void)?
}

class RVRouteProfileView : UIView {
	var profileData: ViewProfileData? {
		didSet {
			let maxCount = profileData!.profileDataSets.reduce(0) { max($0, $1.profileDataPoints.count) }
			self.fullRange = RouteIndexRange(from: 0, to: maxCount-1)
			self.viewRange = self.fullRange
			setNeedsDisplay()
		}
	}
	private var fullRange : RouteIndexRange!
	var viewRange: RouteIndexRange! {
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
				handler(viewRange)
			}
		}
		
		guard gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
		
		let visiblePoints = CGFloat(viewRange.to - viewRange.from)
		let newVisiblePoints = CGFloat(viewRange.to - viewRange.from) / gestureRecognizer.scale
		let change = Int(newVisiblePoints - visiblePoints)
		viewRange = RouteIndexRange(from: viewRange.from - change/2, to: viewRange.to + change/2)
		if viewRange.from < 0 {
			viewRange.to += -viewRange.from
			viewRange.from += -viewRange.from
		}
		if Int(newVisiblePoints) > fullRange.to {
			viewRange = RouteIndexRange(from: 0, to: fullRange.to)
		}
		gestureRecognizer.scale = 1.0
		self.setNeedsDisplay()
	}
	
	@IBAction func didPan(_ gestureRecognizer : UIPanGestureRecognizer) {
		guard gestureRecognizer.view != nil else { return }
		
		switch gestureRecognizer.state {
		case .ended:
			if let handler = profileData?.rangeChangedHandler {
				handler(viewRange!)
			}
		case .began, .changed:
			let widthPerDataPoint = self.bounds.width / CGFloat(self.viewRange.to - self.viewRange.from)
			viewRange.from -= Int(gestureRecognizer.translation(in: self).x / widthPerDataPoint)
			
			if viewRange.from < 0 { viewRange.from = 0 }
			
			viewRange.to = viewRange.from + Int(self.bounds.width / widthPerDataPoint)
			if viewRange.to > fullRange.to {
				viewRange.from -= (viewRange.to - fullRange.to)
				viewRange.to -= (viewRange.to - fullRange.to)
			}
			gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)
			self.setNeedsDisplay()
		default:
			break
			
		}
	}
	
	private func pathForDataSet(_ dataSet: ViewProfileDataSet) -> UIBezierPath? {
		guard fullRange.to > 0, viewRange.to - viewRange.from > 0 else { return nil }
		
		//        appLog.debug("Create path: bounds are \(self.bounds)")
		
		let dataPointsInScope = dataSet.profileDataPoints.enumerated().filter({ $0.offset >= viewRange.from && $0.offset <= viewRange.to })
		let dataMin = dataPointsInScope.reduce(Double.greatestFiniteMagnitude, { min($0, $1.element) })
		let dataMax = dataPointsInScope.reduce(0.0, { max($0, $1.element) })
		let dataRange = max( CGFloat(dataMax - dataMin), 1.0)       // Cannot be zero
		
		//        let dataMin = dataPoints.min()!
		//        let dataRange = CGFloat(dataPoints.max()!) - CGFloat(dataPoints.min()!)
		let yInset = self.bounds.height / 10
		
		let widthPerDataPoint = self.bounds.width / CGFloat(viewRange.to - viewRange.from)
		
		func pointForData(_ data : Double, index : Int) -> CGPoint {
			let x = CGFloat(index) * widthPerDataPoint
			let y = self.bounds.height - (((CGFloat(data-dataMin) / dataRange) * (self.bounds.height-yInset)) + yInset/2)
			return CGPoint(x: x, y: y)
		}
		
		let path = UIBezierPath()
		for (index, point) in dataSet.profileDataPoints.enumerated() {
			if index == viewRange.from {
				path.move(to: pointForData(point, index: 0))
			} else if index > viewRange.from {
				if path.currentPoint == CGPoint.zero {
					appLog.severe("no current point")
					fatalError()
				}
				path.addLine(to: pointForData(point, index: index-viewRange.from))
			}
		}
		
		return path
	}
	
	private func createHighlight() -> UIBezierPath? {
		guard let highlight = profileData?.highlightRange, viewRange.to - viewRange.from > 0 else { return nil }
		
		let widthPerDataPoint = self.bounds.width / CGFloat(self.viewRange.to - self.viewRange.from)
		
		let rect = CGRect(x:( CGFloat(highlight.from) - CGFloat(viewRange.from)) * widthPerDataPoint, y: 0,
						  width: CGFloat(highlight.to - highlight.from) * widthPerDataPoint, height: self.bounds.height)
		
		let path = UIBezierPath(rect: rect)
		return path
	}
	
	override func draw(_ rect: CGRect) {
		// TODO: draw multiple data sets
		guard let dataSet = profileData?.profileDataSets.first else { return }
		
		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}
		if let path = pathForDataSet(dataSet) {
			path.lineWidth = 1.0
			UIColor.blue.setStroke()
			path.stroke()
		}
	}
}

