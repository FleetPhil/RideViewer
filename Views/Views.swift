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
	var map : RVMap? { get }
}

// Route objects: RideRoute, RouteEndPoint, RoutePath
fileprivate class RideRoute {
	var type: RouteViewType
	var route : RouteViewCompatible
	var endPoints : [RouteEnd] = []
	var path : RoutePath?
	
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
	
	var rideRoute : RideRoute!
	
	convenience init?(rideRoute : RideRoute) {
		if let locations = rideRoute.route.map?.polylineLocations(summary: false) {
			self.init(coordinates: UnsafePointer(locations), count: locations.count)
			self.rideRoute = rideRoute
		} else {
			return nil
		}
	}
	
}

fileprivate class RouteEnd : NSObject, MKAnnotation {
	var coordinate: CLLocationCoordinate2D
	var rideRoute: RideRoute
	var isStart : Bool
	
	init(rideRoute : RideRoute, coordinate: CLLocationCoordinate2D, isStart :  Bool) {
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
		self.register(SegmentFinishAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
	}

	
	// Public functions
    func addRoute(_ route : RouteViewCompatible, type : RouteViewType) {
		let rideRoute = RideRoute(route: route, type: type)
		self.routes.append(rideRoute)

		self.setAnnotationsForRideRoute(rideRoute)
        if type != .backgroundSegment {
			if let path = rideRoute.path {
            	self.addOverlay(path)
			}
        }
		setNeedsDisplay()
	}
	
	func setTypeForRoute(_ route : RouteViewCompatible, type : RouteViewType) {
		guard let thisRoute = self.routes.filter({ $0.route === route }).first else {
			appLog.error("Unable to find route to update")
			return
		}
		thisRoute.type = type
		self.setAnnotationsForRideRoute(thisRoute)
		setNeedsDisplay()
	}
	
	fileprivate func setAnnotationsForRideRoute(_ rideRoute : RideRoute) {
		
		var startAnnotation : MKAnnotation? {
			return (self.annotations.filter({$0 is RouteEnd}) as! [RouteEnd]).filter({ $0.rideRoute === rideRoute && $0.isStart }).first
		}
		var finishAnnotation : MKAnnotation? {
			return (self.annotations.filter({$0 is RouteEnd}) as! [RouteEnd]).filter({ $0.rideRoute === rideRoute && !$0.isStart }).first
		}

		// Show start annotation for everything if not already there
		if startAnnotation == nil { self.addAnnotation(rideRoute.startPoint) }
		
		// Show finish annotation unless it's a background segment
		if rideRoute.type != .backgroundSegment && finishAnnotation == nil {
			self.addAnnotation(rideRoute.finishPoint)
		}
		
		// Remove end annotation if it's a background segment
		if rideRoute.type == .backgroundSegment {
			self.removeAnnotation(rideRoute.finishPoint)
		}
	}
	
//	func removeRoute(_ route : RouteViewCompatible) {
//		guard let thisRoute = self.routes.filter({ $0.route === route }).first else {
//			appLog.error("Unable to find route to remove")
//			return
//		}
//		removeOverlays(self.overlays.compactMap({ $0 as? RoutePath }).filter({ $0.rideRoute.route.map == thisRoute.route.map }))
//		removeAnnotations(self.annotations.compactMap({$0 as? RouteEnd}).filter({ thisRoute.endPoints.contains($0) }))
//		
//		for (i, _) in self.routes.enumerated() {
//			self.routes.remove(at: i)
//		}
//	}

	func routes(ofTypes: [RouteViewType]) -> [RouteViewCompatible] {
		return routes.filter({ ofTypes.contains($0.type) }).map({ $0.route })
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
		
		if annotation.isStart {
			return SegmentStartAnnotationView(annotation: annotation, reuseIdentifier: SegmentStartAnnotationView.reuseID)
		} else {
			return SegmentFinishAnnotationView(annotation: annotation, reuseIdentifier: SegmentFinishAnnotationView.reuseID)
		}
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let type = (overlay as? RoutePath)?.rideRoute.type else { return MKOverlayPathRenderer() }
		
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = type.colour
		renderer.lineWidth = type.lineWidth
		return renderer
    }
	
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		let visibleRouteEnds = self.annotations(in: mapView.visibleMapRect).filter({ $0 is RouteEnd }) as! Set<RouteEnd>
		let visibleRoutes = visibleRouteEnds.compactMap({ $0.rideRoute.route })

		viewDelegate?.didChangeVisibleRoutes(Array(visibleRoutes))
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		if let routeEnd = view.annotation as? RouteEnd {
			viewDelegate?.didSelectRoute(route: routeEnd.rideRoute.route)
		}
	}
	
	func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
		if let routeEnd = view.annotation as? RouteEnd {
			viewDelegate?.didDeselectRoute(route: routeEnd.rideRoute.route)
		}
	}
}

// MARK: Route View
protocol RouteViewDelegate : class {
    func newIndexRange(_ range : RouteIndexRange)
}

class RVRouteView : UIView {
    weak var delegate : RouteViewDelegate?

	public var viewRange : RouteIndexRange! {
		didSet {
			setNeedsDisplay()
		}
	}
	
	private var dataPoints : [Double] = []
    
	private var highlightRange : RouteIndexRange? = nil
    private var fullRange : RouteIndexRange? = nil
    private var viewPoints : Int {
        return viewRange == nil ? 0 : viewRange!.to - viewRange!.from
    }

//	required init?(coder aDecoder: NSCoder) {
//		super.init(coder: aDecoder)
//		self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(didPinch)))
//		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didPan)))
//		self.isUserInteractionEnabled = true
//	}
	
	func highlightEffort(_ effort : RVEffort?) {
		self.highlightRange = effort == nil ? nil : effort!.indexRange
        self.setNeedsDisplay()
	}
    
	func drawForActivity(_ activity : RVActivity, streamType : StravaSwift.StreamType) {
		if let stream = activity.streams.filter({ $0.type == streamType.rawValue }).first {
			self.dataPoints = stream.dataPoints.sorted(by: { $0.index < $1.index }).map({ $0.dataPoint })
			self.fullRange = RouteIndexRange(from: 0, to: dataPoints.count)
            self.viewRange = self.fullRange			// Setting view range will trigger redraw
		} else {
			dataPoints = []
			highlightRange = nil
		}
	}
	
	@IBAction func didPinch(_ gestureRecognizer : UIPinchGestureRecognizer) {
		guard gestureRecognizer.view != nil else { return }
        
        if gestureRecognizer.state == .ended {
            delegate?.newIndexRange(self.viewRange)
        }
        
		guard gestureRecognizer.state == .began || gestureRecognizer.state == .changed else { return }
        
        let visiblePoints = CGFloat(self.viewRange.to - self.viewRange.from)
        let newVisiblePoints = CGFloat(self.viewRange.to - self.viewRange.from) / gestureRecognizer.scale
        let change = Int(newVisiblePoints - visiblePoints)
        viewRange = RouteIndexRange(from: viewRange.from - change/2, to: viewRange.to + change/2)
        if viewRange.from < 0 {
            viewRange.to += -viewRange.from
            viewRange.from += -viewRange.from
        }

        if Int(newVisiblePoints) > dataPoints.count {
            viewRange = RouteIndexRange(from: 0, to: dataPoints.count)
        }
		gestureRecognizer.scale = 1.0
        
		self.setNeedsDisplay()
	}

	@IBAction func didPan(_ gestureRecognizer : UIPanGestureRecognizer) {
		guard gestureRecognizer.view != nil else { return }
        
        switch gestureRecognizer.state {
        case .ended:
            delegate?.newIndexRange(viewRange)
        case .began, .changed:
            let widthPerDataPoint = self.bounds.width / CGFloat(self.viewRange.to - self.viewRange.from)
            viewRange.from -= Int(gestureRecognizer.translation(in: self).x / widthPerDataPoint)
            
            if viewRange.from < 0 { viewRange.from = 0 }
            
            viewRange.to = viewRange.from + Int(self.bounds.width / widthPerDataPoint)
            if viewRange.to > dataPoints.count {
                viewRange.from -= (viewRange.to - dataPoints.count)
                viewRange.to -= (viewRange.to - dataPoints.count)
            }
            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: self)
            self.setNeedsDisplay()
        default:
            break
            
        }
	}

	private func createPath() -> UIBezierPath? {
		guard dataPoints.count > 0, viewRange.to - viewRange.from > 0 else { return nil }
        
//        appLog.debug("Create path: bounds are \(self.bounds)")
		
		let dataMin = dataPoints.min()!
		let dataRange = CGFloat(dataPoints.max()!) - CGFloat(dataPoints.min()!)
		let yInset = self.bounds.height / 10
        
        let widthPerDataPoint = self.bounds.width / CGFloat(viewRange.to - viewRange.from)
		
		func pointForData(_ data : Double, index : Int) -> CGPoint {
			let x = CGFloat(index) * widthPerDataPoint
			let y = self.bounds.height - (((CGFloat(data-dataMin) / dataRange) * (self.bounds.height-yInset)) + yInset/2)
			return CGPoint(x: x, y: y)
		}
		
		let path = UIBezierPath()
		for (index, point) in dataPoints.enumerated() {
			if index == viewRange.from {
				path.move(to: pointForData(point, index: 0))
			} else if index > viewRange.from {
                if path.currentPoint == CGPoint.zero {
                    appLog.severe("no current point")
					fatalError()
                }
				path.addLine(to: pointForData(point, index: index-viewRange.from))
			}
		}
		
		return path
	}
	
	private func createHighlight() -> UIBezierPath? {
		guard let highlight = highlightRange, viewRange.to - viewRange.from > 0 else { return nil }
		
        let widthPerDataPoint = self.bounds.width / CGFloat(self.viewRange.to - self.viewRange.from)

		let rect = CGRect(x:( CGFloat(highlight.from) - CGFloat(viewRange.from)) * widthPerDataPoint, y: 0,
						  width: CGFloat(highlight.to - highlight.from) * widthPerDataPoint, height: self.bounds.height)
		
		let path = UIBezierPath(rect: rect)
		return path
	}
	
	override func draw(_ rect: CGRect) {
		if let path = createHighlight() {
			UIColor.lightGray.setFill()
			path.fill()
		}
		if let path = createPath() {
			path.lineWidth = 1.0
			UIColor.blue.setStroke()
			path.stroke()
		}
	}
}

// MARK: RVTableView

protocol SortFilterDelegate : class {
	func tableRowSelectedAtIndex(_ index : IndexPath)
	func tableRowDeselectedAtIndex(_ index : IndexPath)
    func didScrollToVisiblePaths(_ paths : [IndexPath]?)

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
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            sortFilterDelegate?.didScrollToVisiblePaths(self.indexPathsForVisibleRows)
        }
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

