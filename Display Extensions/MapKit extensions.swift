//
//  MapKit extensions.swift
//  RideViewer
//
//  Created by Home on 08/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
	func zoomToAnnotations(_ annotations : [MKAnnotation]) {
		var zoomRect = MKMapRect.null
		for annotation in annotations {
			let annotationPoint = MKMapPoint(annotation.coordinate)
			let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0, height: 0)
			if zoomRect.isNull {
				zoomRect = pointRect
			} else {
				zoomRect = zoomRect.union(pointRect)
			}
		}
		self.setVisibleMapRect(zoomRect.insetBy(dx: -1000, dy: -1000), animated: true)
	}
}
