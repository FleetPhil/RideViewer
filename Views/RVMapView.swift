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
	fileprivate var route : RouteViewCompatible
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
        if let locations = rideRoute.route.coordinates {
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
		case .mainActivity, .activity, .backgroundSegment:     return 2
		case .highlightSegment:                 return 2
		}
	}
	
	var isSegment : Bool {
		switch self {
		case .backgroundSegment, .highlightSegment: return true
		default: return false
		}
	}
}


// MARK: Map view
protocol RideMapViewDelegate : class {
	func didChangeVisibleRoutes(_ routes : [RouteViewCompatible])
	func didSelectRoute(route: RouteViewCompatible)
	func didDeselectRoute(route: RouteViewCompatible)
	
}

class RideMapView : MKMapView, MKMapViewDelegate {
	
	public weak var viewDelegate : RideMapViewDelegate?
	
	private var rideRoutes : [RideRoute] = []
	private let inset : Double = 200
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.register(SegmentStartAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
	}
	
	
	// Public functions
	func addRoute(_ route : RouteViewCompatible, type : RouteViewType) {
		let rideRoute = RideRoute(route: route, type: type)
		self.rideRoutes.append(rideRoute)
		
		// Add start & finish annotations for this route
		self.addAnnotation(rideRoute.startPoint)
		if type != .activity {
			self.addAnnotation(rideRoute.finishPoint)
		}
		
		if type != .backgroundSegment {
			if let path = rideRoute.path {
				self.addOverlay(path)
			}
		}
		setMapRegion()
		setNeedsDisplay()
	}
	
	func setTypeForRoute(_ route : RouteViewCompatible, type : RouteViewType?) {
		guard let thisRouteIndex = rideRoutes.firstIndex(where: { $0.route.isEqual(to: route) }) else {
			appLog.error("Unable to find route to update")
			return
		}

		// Update the annotations for this route to force redisplay
		self.removeAnnotation(rideRoutes[thisRouteIndex].startPoint)
		self.removeAnnotation(rideRoutes[thisRouteIndex].finishPoint)
		
		if type == nil {			// Remove from array
			if let path = rideRoutes[thisRouteIndex].path {
				self.removeOverlay(path)
			}
			rideRoutes.remove(at: thisRouteIndex)
		} else {
			rideRoutes[thisRouteIndex].type = type!
		
			self.addAnnotation(rideRoutes[thisRouteIndex].startPoint)
			self.addAnnotation(rideRoutes[thisRouteIndex].finishPoint)
		}
	}
	
	func routes(ofTypes: [RouteViewType]) -> [RouteViewCompatible] {
		return rideRoutes.filter({ ofTypes.contains($0.type) }).compactMap({ $0.route })
	}
	
	func zoomToRoute(_ route : RouteViewCompatible) {
		guard let thisRoute = rideRoutes.filter({ $0.route.isEqual(to: route) }).first else {
			appLog.error("Unable to find route to update")
			return
		}
		self.zoomToAnnotations(thisRoute.endPoints)
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
	
	// MARK: MapView delegate
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		guard let annotation = annotation as? RouteEnd else { return nil }
		let view = SegmentStartAnnotationView(annotation: annotation, reuseIdentifier: SegmentStartAnnotationView.reuseID)
		
		if annotation.rideRoute?.type == .highlightSegment {
			view.isHidden = false
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
			viewDelegate?.didSelectRoute(route: routeEnd.rideRoute!.route)
		}
	}
	
	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		if let routeEnd = view.annotation as? RouteEnd, routeEnd.rideRoute?.route != nil {
			viewDelegate?.didDeselectRoute(route: routeEnd.rideRoute!.route)
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

