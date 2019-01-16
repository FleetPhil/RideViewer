//
//  Views.swift
//  RideViewer
//
//  Created by Home on 28/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import MapKit

protocol RouteViewCompatible {
	var startLocation : CLLocationCoordinate2D { get }
	var endLocation : CLLocationCoordinate2D { get }
	var map : RVMap? { get }
}

fileprivate class RouteEndPoint : NSObject, MKAnnotation {
	var coordinate: CLLocationCoordinate2D
	var route: RouteViewCompatible
	
	init(route : RouteViewCompatible, isStart :  Bool) {
		self.coordinate = isStart ? route.startLocation : route.endLocation
		self.route = route
		super.init()
	}
}

class RideMapView : MKMapView, MKMapViewDelegate {

	func showForRoute(_ route : RouteViewCompatible) {
        var mapRegion : MKCoordinateRegion? = nil
		
		self.addAnnotation(RouteEndPoint(route: route, isStart: true))
		self.addAnnotation(RouteEndPoint(route: route, isStart: false))
	
		if let map = route.map {
			mapRegion = self.addPolylineForMap(map: map, summary: true)
		} else {
			appLog.debug("No map for route")
		}

        if mapRegion == nil {
            let mapDimension = Measurement(value: 50, unit: UnitLength.kilometers).converted(to: .meters).value
            mapRegion = MKCoordinateRegion(center: route.startLocation, latitudinalMeters: mapDimension, longitudinalMeters: mapDimension)
        }
        self.showAnnotations(self.annotations, animated: true)
        self.setRegion(mapRegion!, animated: true)
	}
	
	private func addPolylineForMap(map : RVMap, summary : Bool = false) -> MKCoordinateRegion? {
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
		return mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.orange
        renderer.lineWidth = 3
        return renderer
    }
}

protocol SortFilterDelegate {
	func tableRowSelectedAtIndex(_ index : IndexPath)
	func sortButtonPressed(sender : UIView)
	func filterButtonPressed(sender : UIView)
}

class RVTableView : UITableView, UITableViewDelegate {
	var sortFilterDelegate : SortFilterDelegate?
    var activityIndicator : UIActivityIndicatorView!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.delegate = self
	}
	
	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		self.delegate = self
	}
	
	// Tableview delegate methods
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		sortFilterDelegate?.tableRowSelectedAtIndex(indexPath)
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView()
		headerView.backgroundColor = UIColor.lightGray
		return headerView
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		let sortButton = UIButton(frame: CGRect(x: 20, y: 0, width: 44, height: view.bounds.maxY))
		sortButton.setTitle("Sort", for: .normal)
		sortButton.addTarget(self, action: #selector(sortButtonPressed), for: .touchUpInside)
		view.addSubview(sortButton)
		
		let filterButton = UIButton(frame: CGRect(x: view.bounds.maxX - 64, y: 0, width: 44, height: view.bounds.maxY))
		filterButton.setTitle("Filter", for: .normal)
		filterButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
		view.addSubview(filterButton)
	}
	
	@IBAction func sortButtonPressed(sender : UIButton) {
		sortFilterDelegate?.sortButtonPressed(sender: sender)
	}
	
	@IBAction func filterButtonPressed(sender : UIButton) {
		sortFilterDelegate?.filterButtonPressed(sender: sender)
	}
    
    func startDataRetrieval() {
        activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.center = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        self.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        self.bringSubviewToFront(activityIndicator)
    }
    
    func endDataRetrieval() {
        activityIndicator.stopAnimating()
    }
    
    func dataRetrievalFailed() {
        activityIndicator.stopAnimating()
        // Display an alert view
        let alert = UIAlertController(title: "", message: "Unable to get Strava Update", preferredStyle: .alert)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1){
            alert.dismiss(animated: true, completion: nil)
        }
    }
}

