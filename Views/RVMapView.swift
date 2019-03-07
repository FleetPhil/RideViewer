//
//  RVMapView.swift
//  RideViewer
//
//  Created by Home on 04/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import MapKit

// Route objects: RideRoute, RouteEndPoint, RoutePath
fileprivate class RideRoute {
	var type: RouteViewType
	fileprivate weak var route : RouteViewCompatible?
	fileprivate var endPoints : [RouteEnd] = []
	fileprivate var path : RoutePath?
	
	init(route : RouteViewCompatible, type : RouteViewType) {
		self.route = route
		self.type = type
		
		self.endPoints.append(RouteEnd(rideRoute: self, coordinate: route.startLocation, isStart: true))
		self.endPoints.append(RouteEnd(rideRoute: self, coordinate: route.endLocation, isStart: false))
		self.path = RoutePath(rideRoute: self)
	}
	var startPoint : RouteEnd { return endPoints[0] }
	var finishPoint : RouteEnd { return endPoints[1] }
}

fileprivate class RoutePath : MKPolyline {
	
	weak var rideRoute : RideRoute?
	
	convenience init?(rideRoute : RideRoute) {
        if let locations = rideRoute.route?.coordinates {
			self.init(coordinates: UnsafePointer(locations), count: locations.count)
			self.rideRoute = rideRoute
		} else {
			return nil
		}
	}
}

fileprivate class RouteEnd : NSObject, MKAnnotation {
	internal var coordinate: CLLocationCoordinate2D
	weak var rideRoute: RideRoute?
	var isStart : Bool
	
	fileprivate init(rideRoute : RideRoute, coordinate: CLLocationCoordinate2D, isStart :  Bool) {
		self.coordinate = coordinate
		self.rideRoute = rideRoute
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

public enum RouteViewType {
	case mainActivity
	case activity
	case highlightSegment
	case backgroundSegment
	
	var colour : UIColor {
		switch self {
		case .mainActivity:			return UIColor.red
		case .activity:             return UIColor.orange
		case .highlightSegment:     return UIColor.green
		case .backgroundSegment:    return UIColor.darkGray
			
		}
	}
	var lineWidth : CGFloat {
		switch self {
		case .mainActivity, .activity, .backgroundSegment:     return 3
		case .highlightSegment:                 return 5
		}
	}
	
	var isSegment : Bool {
		switch self {
		case .backgroundSegment, .highlightSegment: return true
		default: return false
		}
	}
}

public struct RouteIndexRange {
	var from: Int
	var to: Int
}

// MARK: Map view
protocol RideMapViewDelegate : class {
	func didChangeVisibleRoutes(_ routes : [RouteViewCompatible])
	func didSelectRoute(route: RouteViewCompatible)
	func didDeselectRoute(route: RouteViewCompatible)
	
}

class RideMapView : MKMapView, MKMapViewDelegate {
	
	public weak var viewDelegate : RideMapViewDelegate?
	
	private var routes : [RideRoute] = []
	private let inset : Double = 200
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.register(MapPhotoView.self, forAnnotationViewWithReuseIdentifier: "photoView")
		self.register(SegmentStartAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
	}
	
	
	// Public functions
	func addRoute(_ route : RouteViewCompatible, type : RouteViewType) {
		let rideRoute = RideRoute(route: route, type: type)
		self.routes.append(rideRoute)
		
		// Add start & finish annotations for this route
		self.addAnnotation(rideRoute.startPoint)
		self.addAnnotation(rideRoute.finishPoint)
		
		if type != .backgroundSegment {
			if let path = rideRoute.path {
				self.addOverlay(path)
			}
		}
		setMapRegion()
		setNeedsDisplay()
	}
	
	func setTypeForRoute(_ route : RouteViewCompatible, type : RouteViewType) {
		guard let thisRoute = self.routes.filter({ $0.route === route }).first else {
			appLog.error("Unable to find route to update")
			return
		}
		thisRoute.type = type
		
		// Update the annotations for this route to force redisplay
		self.removeAnnotation(thisRoute.startPoint)
		self.removeAnnotation(thisRoute.finishPoint)
		
		self.addAnnotation(thisRoute.startPoint)
		self.addAnnotation(thisRoute.finishPoint)
		
		//		self.showAnnotations([thisRoute.startPoint, thisRoute.finishPoint], animated: true)
	}
	
	func routes(ofTypes: [RouteViewType]) -> [RouteViewCompatible] {
		return routes.filter({ ofTypes.contains($0.type) }).compactMap({ $0.route })
	}
	
	func setMapRegion() {
		if self.overlays.count == 0 {
			let zoomRect = annotations.reduce(MKMapRect.null, {
				$0.union(MKMapRect(origin: MKMapPoint($1.coordinate), size: MKMapSize(width: 0.1, height: 0.1)))
			})
			self.setVisibleMapRect(zoomRect.insetBy(dx: -inset*100, dy: -inset*100), animated: true)
			return
		}
		// Calculate the region that includes all of the routes
		if self.overlays.count == 1 {
			self.setRegion(MKCoordinateRegion(self.overlays[0].boundingMapRect.insetBy(dx: inset, dy: inset)), animated: true)
		} else {
			self.setRegion(MKCoordinateRegion(self.overlays.map ({ $0.boundingMapRect }).reduce(MKMapRect.null, { $0.union($1) }).insetBy(dx: inset, dy: inset)), animated: true)
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
		}
		
		guard let annotation = annotation as? RouteEnd else { return nil }
		let view = SegmentStartAnnotationView(annotation: annotation, reuseIdentifier: SegmentStartAnnotationView.reuseID)
		
		if annotation.rideRoute?.type == .highlightSegment {
			view.isHidden = false
			view.isSelected = true
			view.clusteringIdentifier = nil
			return view
		} else {
			view.isSelected = false
			if annotation.isStart {
				view.isHidden = false
			} else {
				view.isHidden = true
			}
			view.clusteringIdentifier = "segment"
			return view
		}
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		guard let type = (overlay as? RoutePath)?.rideRoute?.type else { return MKOverlayPathRenderer() }
		
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = type.colour
		renderer.lineWidth = type.lineWidth
		return renderer
	}
	
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		let visibleRouteEnds = self.annotations(in: mapView.visibleMapRect).filter({ $0 is RouteEnd }) as! Set<RouteEnd>
		let visibleRoutes = visibleRouteEnds.compactMap({ $0.rideRoute?.route })
		
		viewDelegate?.didChangeVisibleRoutes(Array(visibleRoutes))
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		if let routeEnd = view.annotation as? RouteEnd, routeEnd.rideRoute?.route != nil {
			viewDelegate?.didSelectRoute(route: routeEnd.rideRoute!.route!)
		}
	}
	
	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		if let routeEnd = view.annotation as? RouteEnd, routeEnd.rideRoute?.route != nil {
			viewDelegate?.didDeselectRoute(route: routeEnd.rideRoute!.route!)
		}
	}
}

/// - Tag: Segment start and end annotation views
class SegmentStartAnnotationView: MKMarkerAnnotationView {
	
	static let reuseID = "segmentAnnotation"
	
	override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
		super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForDisplay() {
		super.prepareForDisplay()
		displayPriority = .required
		
		let annotation = self.annotation as! RouteEnd
		if annotation.isStart {
			markerTintColor = UIColor.segmentMarkerSelectedColour
			glyphText = "🇬🇧"
		} else {
			markerTintColor = UIColor.segmentMarkerFinishColour
			glyphText = "🏁"
		}
	}
}

