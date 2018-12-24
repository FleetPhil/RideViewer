//
//  Strava Authorise.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import StravaSwift

class StravaAuthorise {
	var strava : StravaClient
	
	var code: String?
	private var token: OAuthToken?
	
	init () {
		let config = StravaConfig(
			clientId: 8785,
			clientSecret: "3b200baf949c02246425b3b6fb5957409a7fdb00",
			redirectUri: "rideviewer://localhost"
		)
		
		strava = StravaClient.sharedInstance.initWithConfig(config)

	}

	func authorise() {
		strava.authorize()
	}
	
	func getToken(code : String) throws -> OAuthToken? {
		var token : OAuthToken? = nil
		do {
			try strava.getAccessToken(code) { returnedToken in
				token = returnedToken
			}
		} catch (let error) {
			appLog.error("Strava token error \(error)")
		}
		return token
	}
	
}
