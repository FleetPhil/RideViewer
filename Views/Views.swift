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
	var isStart : Bool
	
	init(route : RouteViewCompatible, isStart :  Bool) {
		self.coordinate = isStart ? route.startLocation : route.endLocation
		self.route = route
		self.isStart = isStart
		super.init()
	}
}

fileprivate class PhotoAnnotation : NSObject, MKAnnotation {
	var coordinate: CLLocationCoordinate2D
	var image : UIImage
	init(image : UIImage,  location : CLLocation) {
		self.coordinate = location.coordinate
		self.image = image
		super.init()
	}
}

fileprivate class MapPhotoView : MKAnnotationView {
	
}

fileprivate class RideRouteLine : MKPolyline {
	var highlighted : Bool = false
	var route : RouteViewCompatible!
	
	convenience init(coordinates: UnsafePointer<CLLocationCoordinate2D>, count: Int, highlighted : Bool, route: RouteViewCompatible) {
		self.init(coordinates: coordinates, count: count)
		self.highlighted = highlighted
		self.route = route
	}
}

class RideMapView : MKMapView, MKMapViewDelegate {
	
	var mapRegion : MKCoordinateRegion!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.register(MapPhotoView.self, forAnnotationViewWithReuseIdentifier: "photoView")
	}
	
	// Public functions
	func addRoute(_ route : RouteViewCompatible, highlighted: Bool) {
		if highlighted {
			self.addAnnotation(RouteEndPoint(route: route, isStart: true))
			self.addAnnotation(RouteEndPoint(route: route, isStart: false))
		}
		guard let locations = route.map?.polylineLocations(summary: false), locations.count > 0 else { return }
		self.addOverlay(RideRouteLine(coordinates: locations, count: locations.count, highlighted: highlighted, route: route))
		
		setMapRegion()
	}
	
	func removeRoute(_ route : RouteViewCompatible) {
		removeOverlays(self.overlays.compactMap({ $0 as? RideRouteLine }).filter({	$0.route.map == route.map }))
		removeAnnotations(self.annotations.compactMap({$0 as? RouteEndPoint}).filter({ $0.route.map == route.map }))
		
		setMapRegion()
	}
	
	private func setMapRegion() {
		if self.overlays.count == 0 {
			return
		}
		// Calculate the region that includes all of the routes
		if self.overlays.count == 1 {
			self.setRegion(MKCoordinateRegion(self.overlays[0].boundingMapRect), animated: true)
		} else {
			self.setRegion(MKCoordinateRegion(self.overlays.map ({ $0.boundingMapRect }).reduce(MKMapRect.null, { $0.union($1) })), animated: true)
		}
	}

	func addPhoto(image : UIImage?, location : CLLocation?) {
		guard let image = image, let location = location else { return }
		
		self.removeAnnotations(self.annotations.filter({ $0 is PhotoAnnotation }))
		self.addAnnotation(PhotoAnnotation(image: image, location: location))
	}

    // MARK: MapView delegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let photoAnnotation = annotation as? PhotoAnnotation {
			let view = mapView.dequeueReusableAnnotationView(withIdentifier: "photoView", for: photoAnnotation)
			view.image = photoAnnotation.image.renderResizedImage(newWidth: 30)
			return view
		} else {
			let identifier = "EndMarker"
			var view: MKMarkerAnnotationView
			if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
				view = dequeuedView
			} else {
				view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
				view.canShowCallout = false
				view.calloutOffset = CGPoint(x: -5, y: 5)
				view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
			}
			if let endPoint = annotation as? RouteEndPoint {
				if endPoint.isStart {
					view.glyphText = "🇬🇧"
					view.glyphTintColor = UIColor.lightGray
				} else {
					view.glyphText = "🏁"
					view .glyphTintColor = UIColor.green
				}
			}
			return view
		}
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let highlighted = (overlay as? RideRouteLine)?.highlighted ?? false
		
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = highlighted ? UIColor.red : UIColor.orange
		renderer.lineWidth = highlighted ? 5 : 3
		return renderer
    }
}

protocol SortFilterDelegate : class {
	func tableRowSelectedAtIndex(_ index : IndexPath)
	func tableRowDeselectedAtIndex(_ index : IndexPath)
	func sortButtonPressed(sender : UIView)
	func filterButtonPressed(sender : UIView)
}

// Default behaviour for optional functions
extension SortFilterDelegate {
	func tableRowDeselectedAtIndex(_ index : IndexPath) {
		return
	}
}

class RVTableView : UITableView, UITableViewDelegate {
	weak var sortFilterDelegate : SortFilterDelegate?
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
	
	func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		sortFilterDelegate?.tableRowDeselectedAtIndex(indexPath)
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

