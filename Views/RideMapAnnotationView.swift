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

