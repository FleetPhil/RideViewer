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
			self.contentMode = ContentMode.redraw
			setNeedsDisplay()
		}
	}
	
	var sizeIsSet : Bool = false

	// MARK: Set the view size
	//		There is no instrinsic size for this view in the storyboard so one needs to be defined (i.e. bounds set)
	//		If the superview is a scroll view and has a defined content size then use that
	//		If not use the bounds of the superview as the content size
	override func layoutSubviews() {
		if !sizeIsSet {
			if let scrollView = superview as? UIScrollView {
				self.bounds = scrollView.bounds
				self.frame.origin = CGPoint(x: 0, y: 0)
				scrollView.contentSize = self.bounds.size
				sizeIsSet = true
				appLog.debug("Bounds set to \(self.bounds)")
			}
		}
		super.layoutSubviews()
	}
	
	// MARK: Functions to plot values
	
	// Return the point in the given CGRect that shows the x and y values scaled to the bounds
	// x and y values are in the frame of the secondary, bounds are in the frame of the primary
	private func plot(rect : CGRect, x : Double, y: Double, bounds : DataBounds) -> CGPoint? {
		guard y>=bounds.minY, y<=bounds.maxY, x>=bounds.minX else {
//			appLog.error("Error: data point to plot out of bounds")
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

		let drawRect = self.frame
		
		guard let topLeft = plot(rect: drawRect, x: highlight.from, y: profileData!.mainDataBounds.minY, bounds: profileData!.mainDataBounds),
			let bottomRight = plot(rect: drawRect, x: highlight.to, y: profileData!.mainDataBounds.maxY, bounds: profileData!.mainDataBounds)
			else {
				appLog.error("Plot for highlight range out of bounds")
				return nil
		}
		let highlightRect = CGRect(origin: topLeft, size: CGSize(width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y))
		let path = UIBezierPath(rect: highlightRect)
		return path
	}
	
	override func draw(_ rect: CGRect) {
		
		guard profileData != nil else { return }
		self.backgroundColor = UIColor.white

		let drawRect = self.bounds
		
		// If the device has been rotated while the scrollview is zoomed, the content height will have been scaled and needs to be adjusted
		if let sv = superview as? UIScrollView {
			if sv.contentSize.height > drawRect.height {
				sv.contentSize.height = drawRect.height
			}
		}

		// Calculate the zoom level and width for the lines
		let zoom = frame.width / bounds.width
        let lineWidth = zoom == 1.0 ? 1.0 : 1.0 / zoom
		
		appLog.verbose(self.bounds.display(name: "Bounds") + " " + self.frame.display(name: "Frame") + " Zoom: \(zoom.fixedFraction(digits: 1))")
		appLog.verbose((self.superview! as! UIScrollView).contentSize.display(name: "Content size"))

		// Draw lines for axes
		let path = UIBezierPath()
		path.move(to: CGPoint(x: 0.0, y: 0.0))
		path.addLine(to: CGPoint(x: 0.0, y: drawRect.maxY))
		path.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
		UIColor.lightGray.setStroke()
		path.lineWidth = lineWidth
		path.stroke()
		
		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}
		
		appLog.verbose("Draw: \(profileData!.profileDataSets.map { ($0.profileDataType, $0.profileDisplayType) })")
		
		for dataSet in profileData!.profileDataSets {
			appLog.verbose("Draw set: \(dataSet.profileDataType), \(dataSet.profileDisplayType), \(dataSet.dataPoints.count) values")
			appLog.verbose("Axis range is \(dataSet.dataPoints.first!.axisValue) to \(dataSet.dataPoints.last!.axisValue), axis bounds are \(profileData!.mainDataBounds)")

			switch dataSet.profileDisplayType {
			
			case .primary, .secondary:
				// Primary and secondary draw as a line with data bounds set by primary
				let pointsToDraw = plotValues(rect: drawRect, dataValues: dataSet.dataPoints, dataBounds: profileData!.mainDataBounds)
				let path = UIBezierPath()
				path.lineWidth = lineWidth
				path.move(to: pointsToDraw[0])
				for i in 1..<pointsToDraw.count {
					path.addLine(to: pointsToDraw[i])
				}
				dataSet.profileDisplayType.displayColour.setStroke()
				path.stroke()
			
			case .background:
				// Background draws as a shaded background
				// Data bounds for the background are relative to the background bounds, not the primary (i.e. plotted on a secondary y axis)
				
				let dataBounds = dataSet.dataBounds
				let viewBounds = CGRect(x: 0, y: drawRect.height * 0.25 , width: drawRect.width, height: drawRect.height * 0.75 ).inset(by: UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0))
				let pointsToDraw = plotValues(rect: viewBounds, dataValues: dataSet.dataPoints, dataBounds: dataBounds)
				
				if pointsToDraw.count == 0 {
					appLog.error("No points to draw")
					return
				}

				let path = UIBezierPath()
				path.move(to: pointsToDraw[0])
				for i in 1..<pointsToDraw.count {
					path.addLine(to: pointsToDraw[i])
				}
				path.addLine(to: CGPoint(x: pointsToDraw.last!.x, y: self.bounds.maxY))
				path.addLine(to: CGPoint(x: pointsToDraw[0].x, y: self.bounds.maxY))
				path.addLine(to: pointsToDraw[0])
				let backgroundColour = UIColor.init(displayP3Red: 0.0, green: 0, blue: 1, alpha: 0.2)
				backgroundColour.setFill()
				path.fill()
				
				drawLinearGradient(inside: path, start: CGPoint(x: 0, y: viewBounds.minY), end: CGPoint(x: 0.0, y: viewBounds.maxY-1), colors: [backgroundColour, UIColor.white])
				
			}
		}
	}
	
	private func drawLinearGradient(inside path:UIBezierPath, start:CGPoint, end:CGPoint, colors:[UIColor])
	{
		guard let ctx = UIGraphicsGetCurrentContext() else { return }
		
		ctx.saveGState()
		path.addClip() // use the path as the clipping region
		
		let cgColors = colors.map({ $0.cgColor })
		guard let gradient = CGGradient(colorsSpace: nil, colors: cgColors as CFArray, locations: nil)
			else { return }
		
		ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
		
		ctx.restoreGState() // remove the clipping region for future draw operations
	}
	
	override var transform: CGAffineTransform {
		get { return super.transform }
		set {
			let unzoomedViewHeight = self.bounds.height
			var t = newValue
			t.d = 1.0
			t.ty = (1.0 - t.a) * unzoomedViewHeight/2
			super.transform = t
		}
	}
}

extension CGRect {
	func display(name : String = "") -> String {
		return self.size.display(name: name)
	}
}

extension CGSize {
	func display(name : String = "") -> String {
		return name + "(W: " + self.width.fixedFraction(digits: 1) + ", H: " + self.height.fixedFraction(digits: 1) + ")"
	}
}

