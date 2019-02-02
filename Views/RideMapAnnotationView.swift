//
//  RideMapAnnotationView.swift
//  RideViewer
//
//  Created by Home on 01/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import MapKit

private let multiWheelCycleClusterID = "multiWheelCycle"

/// - Tag: Segment start and end annotation views
class SegmentStartAnnotationView: MKMarkerAnnotationView {
	
	static let reuseID = "startAnnotation"

	override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
		super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
		clusteringIdentifier = "start"
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForDisplay() {
		super.prepareForDisplay()
		displayPriority = .defaultLow
		markerTintColor = UIColor.segmentMarkerStartColour
		glyphText = "🏳️"
	}
}

class SegmentFinishAnnotationView: MKMarkerAnnotationView {
	
	static let reuseID = "finishAnnotation"
	
	override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
		super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
		clusteringIdentifier = "finish"
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForDisplay() {
		super.prepareForDisplay()
		displayPriority = .required
		markerTintColor = UIColor.segmentMarkerFinishColour
		glyphText = "🏁"
	}
}

