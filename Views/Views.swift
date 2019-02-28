//
//  Views.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import MapKit
import StravaSwift

// MARK: RideMapView

// underlying objects
protocol RouteViewCompatible : class {
	var startLocation : CLLocationCoordinate2D { get }
	var endLocation : CLLocationCoordinate2D { get }
	var coordinates : [CLLocationCoordinate2D]? { get }
}

extension UIImage {
	func renderResizedImage (newWidth: CGFloat) -> UIImage {
		let scale = newWidth / self.size.width
		let newHeight = self.size.height * scale
		let newSize = CGSize(width: newWidth, height: newHeight)
		
		let renderer = UIGraphicsImageRenderer(size: newSize)
		
		let image = renderer.image { (context) in
			self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
		}
		return image
	}
}

