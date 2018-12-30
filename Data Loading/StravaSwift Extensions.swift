//
//  StravaSwift Extensions.swift
//  RideViewer
//
//  Created by Home on 25/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import StravaSwift
import CoreLocation

extension Location {
	var location2D : CLLocationCoordinate2D? {
		if let lat = self.lat, let long = self.lng {
			return CLLocationCoordinate2D(latitude: lat, longitude: long)
		} else {
			return nil
		}
	}
}
