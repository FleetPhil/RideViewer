//
//  Views.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import MapKit

class RideMapView : MKMapView, MKMapViewDelegate {
	func showForActivity(_ activity : RVActivity) {

		self.addAnnotation(activity)

		let mapDimension = Measurement(value: 50, unit: UnitLength.miles).converted(to: .meters).value
		self.setRegion(self.regionThatFits(MKCoordinateRegion.init(center: activity.startLocation, latitudinalMeters: mapDimension, longitudinalMeters: mapDimension)), animated: true)
		self.showAnnotations(self.annotations, animated: true)
	}
	
	override func view(for annotation: MKAnnotation) -> MKAnnotationView? {
		return MKAnnotationView(annotation: annotation, reuseIdentifier: "Ride")
	}
}

extension RVActivity : MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		return self.startLocation
	}
}

