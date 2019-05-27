//
//  General Utilities.swift
//  RideViewer
//
//  Created by Home on 19/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import MapKit

extension Date {
	// return true if date is in the specified period
	func isDuring(startDate : Date, elapsedTime : Duration) -> Bool {
		return (self >= startDate && self <= startDate + (elapsedTime as TimeInterval)) ? true : false
	}
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
	return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension MKMapView {
	var visibleAnnotations : [MKAnnotation] {
		return self.annotations(in: self.visibleMapRect).map { obj -> MKAnnotation in return obj as! MKAnnotation }
	}
}
