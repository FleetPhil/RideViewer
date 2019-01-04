//
//  Strava Manager.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation
import StravaSwift
import CoreData

class StravaManager : TokenDelegate {
	func get() -> OAuthToken? {
		return token
	}
	
	func set(_ token: OAuthToken?) {
		self.token = token
	}
	
	static let sharedInstance = StravaManager()
	var strava : StravaClient!
	
	private var token: OAuthToken!
	
	private init () {
		let config = StravaConfig(clientId: 8785,
							 clientSecret: "3b200baf949c02246425b3b6fb5957409a7fdb00",
							 redirectUri: "rideviewer://localhost",
							 scope: .viewPrivate,
							 delegate: self)
		
		strava = StravaClient.sharedInstance.initWithConfig(config)

	}

	func authorise() {
		strava.authorize()
	}
	
	func getToken(code : String, completion : @escaping (Bool) -> Void) {
		do {
			try strava.getAccessToken(code) { [weak self] returnedToken in
				if let `self` = self, let validToken = returnedToken {
					appLog.debug("Got token")
					self.token = validToken
					completion(true)
				} else {
					// Async
					appLog.debug("Async return")
				}
			}
		} catch (let error) {
			appLog.error("Strava token error \(error)")
			completion(false)
		}
	}
	
	func getAthleteActivities(page : Int, context : NSManagedObjectContext) {
		try? StravaClient.sharedInstance.request(Router.athleteActivities(params: ["per_page":100, "page":page]), result: { [weak self] (activities: [Activity]?) in
			guard let `self` = self, let activities = activities else { return }
			
			appLog.debug("Retrieved \(activities.count) activities for page \(page)")
			if activities.count > 0 {
				activities.forEach {
					let _ = RVActivity.create(activity: $0, context: context)
				}
				context.saveContext()
				self.getAthleteActivities(page: page + 1, context: context)		// get next page
			}
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}
	
    // Get details for specified activity
	func updateActivity(_ activity : RVActivity, context : NSManagedObjectContext, completionHandler : @escaping (()->Void)) {
		guard token != nil else { return }

		try? StravaClient.sharedInstance.request(Router.activities(id: Router.Id(activity.id), params: ["include_all_efforts":false]), result: { (activities: Activity?) in
			guard let activity = activities else { return }
			
//			appLog.debug("Retrieved activity details for \(activity.name ?? "None?")")
			let _ = RVActivity.create(activity: activity, context: context)
			context.saveContext()
			completionHandler()
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}

	func updateSegment(_ segment : RVSegment, context : NSManagedObjectContext, completionHandler : @escaping (()->Void)) {
		guard token != nil else { return }
		
		try? StravaClient.sharedInstance.request(Router.segments(id: Router.Id(segment.id), params: [:]), result: { (newSegment: Segment?) in
			guard let segment = newSegment else { return }
			
//			appLog.debug("Retrieved segment details for \(segment.name ?? "None?")")
			let _ = RVSegment.create(segment: segment, context: context)
			context.saveContext()
			completionHandler()
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}

	
}
