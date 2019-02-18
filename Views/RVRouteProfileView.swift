//
//  RVRouteProfileView.swift
//  RideViewer
//
//  Created by Home on 04/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit
import StravaSwift

protocol ProfileViewDelegate : class {
	func newIndexRange(_ range : RouteIndexRange)
}

//struct ViewProfile {
//	
//}

class RVRouteProfileView : UIView {
	weak var delegate : ProfileViewDelegate?
	
	public var viewRange : RouteIndexRange! {
		didSet {
			setNeedsDisplay()
		}
	}
	
	private var dataPoints : [Double] = []
	
	private var highlightRange : RouteIndexRange? = nil
	private var fullRange : RouteIndexRange? = nil
	private var viewPoints : Int {
		return viewRange == nil ? 0 : viewRange!.to - viewRange!.from
	}
	
	//	required init?(coder aDecoder: NSCoder) {
	//		super.init(coder: aDecoder)
	//		self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(didPinch)))
	//		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
	//		self.isUserInteractionEnabled = true
	//	}
	
	func highlightEffort(_ effort : RVEffort?) {
		self.highlightRange = effort == nil ? nil : effort!.indexRange
		self.setNeedsDisplay()
	}
	
	func drawForActivity(_ activity : RVActivity, streamType : StravaSwift.StreamType) {
		if let stream = activity.streams.filter({ $0.type == streamType.rawValue }).first {
			self.dataPoints = stream.dataPoints.sorted(by: { $0.index < $1.index }).map({ $0.dataPoint })
			self.fullRange = RouteIndexRange(from: 0, to: dataPoints.count)
			self.viewRange = self.fullRange			// Setting view range will trigger redraw
		} else {
			dataPoints = []
			highlightRange = nil
		}
	}
	
	@IBAction func didPinch(_ gestureRecognizer : UIPinchGestureRecognizer) {
		guard gestureRecognizer.view != nil else { return }
		
		if gestureRecognizer.state == .ended {
			delegate?.newIndexRange(self.viewRange)
		}
		
		guard gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
		
		let visiblePoints = CGFloat(self.viewRange.to - self.viewRange.from)
		let newVisiblePoints = CGFloat(self.viewRange.to - self.viewRange.from) / gestureRecognizer.scale
		let change = Int(newVisiblePoints - visiblePoints)
		viewRange = RouteIndexRange(from: viewRange.from - change/2, to: viewRange.to + change/2)
		if viewRange.from < 0 {
			viewRange.to += -viewRange.from
			viewRange.from += -viewRange.from
		}
		
		if Int(newVisiblePoints) > dataPoints.count {
			viewRange = RouteIndexRange(from: 0, to: dataPoints.count)
		}
		gestureRecognizer.scale = 1.0
		
		self.setNeedsDisplay()
	}
	
	@IBAction func didPan(_ gestureRecognizer : UIPanGestureRecognizer) {
		guard gestureRecognizer.view != nil else { return }
		
		switch gestureRecognizer.state {
		case .ended:
			delegate?.newIndexRange(viewRange)
		case .began, .changed:
			let widthPerDataPoint = self.bounds.width / CGFloat(self.viewRange.to - self.viewRange.from)
			viewRange.from -= Int(gestureRecognizer.translation(in: self).x / widthPerDataPoint)
			
			if viewRange.from < 0 { viewRange.from = 0 }
			
			viewRange.to = viewRange.from + Int(self.bounds.width / widthPerDataPoint)
			if viewRange.to > dataPoints.count {
				viewRange.from -= (viewRange.to - dataPoints.count)
				viewRange.to -= (viewRange.to - dataPoints.count)
			}
			gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)
			self.setNeedsDisplay()
		default:
			break
			
		}
	}
	
	private func createPath() -> UIBezierPath? {
		guard dataPoints.count > 0, viewRange.to - viewRange.from > 0 else { return nil }
		
		//        appLog.debug("Create path: bounds are \(self.bounds)")
		
		let dataPointsInScope = dataPoints.enumerated().filter({ $0.offset >= viewRange.from && $0.offset <= viewRange.to })
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
		for (index, point) in dataPoints.enumerated() {
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
		guard let highlight = highlightRange, viewRange.to - viewRange.from > 0 else { return nil }
		
		let widthPerDataPoint = self.bounds.width / CGFloat(self.viewRange.to - self.viewRange.from)
		
		let rect = CGRect(x:( CGFloat(highlight.from) - CGFloat(viewRange.from)) * widthPerDataPoint, y: 0,
						  width: CGFloat(highlight.to - highlight.from) * widthPerDataPoint, height: self.bounds.height)
		
		let path = UIBezierPath(rect: rect)
		return path
	}
	
	override func draw(_ rect: CGRect) {
		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}
		if let path = createPath() {
			path.lineWidth = 1.0
			UIColor.blue.setStroke()
			path.stroke()
		}
	}
}

