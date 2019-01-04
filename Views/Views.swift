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
        var mapRegion : MKCoordinateRegion? = nil

		self.addAnnotation(activity)
		if let map = activity.map {
			mapRegion = self.addPolylineForMap(map: map, summary: true)
		} else {
			appLog.debug("No map for activity")
		}

        if mapRegion == nil {
            let mapDimension = Measurement(value: 50, unit: UnitLength.miles).converted(to: .meters).value
            mapRegion = MKCoordinateRegion(center: activity.startLocation, latitudinalMeters: mapDimension, longitudinalMeters: mapDimension)
        }
        self.showAnnotations(self.annotations, animated: true)
        self.setRegion(mapRegion!, animated: true)
	}
	
	func addPolylineForMap(map : RVMap, summary : Bool = false) -> MKCoordinateRegion? {
        guard let locations = map.polylineLocations(summary: summary), locations.count > 0 else { return nil }
        
		let polyline = MKPolyline(coordinates: locations, count: locations.count)
		self.addOverlay(polyline)
        
        // Work out the region covered by the map and return it
        let maxLat = (locations.map { $0.latitude }).max()!
        let minLat = (locations.map { $0.latitude }).min()!
        let maxLong = (locations.map { $0.longitude }).max()!
        let minLong = (locations.map { $0.longitude }).min()!
        let mapCentre = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLong + maxLong) / 2)
        let mapSpan = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLong - minLong)
        return MKCoordinateRegion(center: mapCentre, span: mapSpan)
	}
    
    // MARK: MapView delegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return MKAnnotationView(annotation: annotation, reuseIdentifier: "Ride")
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.orange
        renderer.lineWidth = 3
        return renderer
    }
    

}

extension RVActivity : MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		return self.startLocation
	}
}

