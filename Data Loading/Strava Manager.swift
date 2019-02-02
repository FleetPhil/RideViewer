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
	private var newActivityCount = 0
	private var lastActivity : Date? = nil
	
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
	
    func getAthleteActivities(page : Int, context : NSManagedObjectContext, completionHandler : @escaping ((_ newActivities : Int)->Void)) {
		var params = ["per_page":100, "page":page]

		if page == 1 {
		// Get time of latest activity and save the date 
			if let activities : [RVActivity] = context.fetchObjects() {
				if activities.count > 0 {
					self.lastActivity = activities.map({ $0.startDate as Date }).max()
				}
				self.newActivityCount = 0
			}
		}
		
		if self.lastActivity != nil {
			params["after"] = Int(self.lastActivity!.timeIntervalSince1970)
		}
		
		try? StravaClient.sharedInstance.request(Router.athleteActivities(params: params), result: { [weak self] (activities: [Activity]?) in
			guard let `self` = self, let activities = activities else { return }
			
			appLog.debug("Retrieved \(activities.count) activities for page \(page)")
			if activities.count > 0 {
				activities.forEach {
					let _ = RVActivity.create(activity: $0, context: context)
				}
				context.saveContext()
				self.newActivityCount = self.newActivityCount + activities.count
                self.getAthleteActivities(page: page + 1, context: context, completionHandler: completionHandler)		// get next page
			} else {
				// No more activities to load
				self.lastActivity = nil
                completionHandler(self.newActivityCount)
			}
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}
	
	// Get details for specified activity
    func updateActivity(_ activity : RVActivity, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
		guard token != nil else {
            completionHandler(false)
            return
        }
		
		try? StravaClient.sharedInstance.request(Router.activities(id: Router.Id(activity.id), params: ["include_all_efforts":false]), result: { (activities: Activity?) in
			guard let activity = activities else {
                completionHandler(false)
                return
            }
			
			//			appLog.debug("Retrieved activity details for \(activity.name ?? "None?")")
			let _ = RVActivity.create(activity: activity, context: context)
			context.saveContext()
			completionHandler(true)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	func updateSegment(_ segment : RVSegment, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
		guard token != nil else {
			completionHandler(false)
			return
		}
		
		try? StravaClient.sharedInstance.request(Router.segments(id: Router.Id(segment.id), params: [:]), result: { (newSegment: Segment?) in
			guard let segment = newSegment else { return }
			
			let _ = RVSegment.create(segment: segment, context: context)
			context.saveContext()
			completionHandler(true)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	func effortsForSegment(_ segment : RVSegment, page : Int, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
		guard token != nil else { return }
		
		try? StravaClient.sharedInstance.request(Router.segmentsEfforts(id: Router.Id(segment.id), params: ["page":page, "per_page" : 100]), result: { [weak self ] (efforts : [Effort]?) in
			guard let `self` = self, let efforts = efforts else {
				completionHandler(false)
				return
			}
			
			if efforts.count > 0 {
				efforts.forEach {
					if let activityID = $0.activity?.id {
						let _ = RVEffort.create(effort: $0, forActivity: RVActivity.get(identifier: activityID, inContext: context)!, context: context)
					}
				}
				context.saveContext()
				self.effortsForSegment(segment, page: page + 1, context: context, completionHandler: completionHandler)
			} else {			// Finished
				// We have all current efforts for this segment
				segment.allEfforts = true
				completionHandler(true)
			}
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	func streamsForActivity(_ activity : RVActivity, context: NSManagedObjectContext, completionHandler: @escaping ((Bool)->Void)) {
		guard token != nil else { return }
		
		try? StravaClient.sharedInstance.request(Router.activityStreams(id: Router.Id(activity.id), types: "distance,altitude,watts,heartrate"), result: { (streams : [StravaSwift.Stream]?) in
            guard let streams = streams else {
				completionHandler(false)
				return
			}
			
			for stream in streams {
//				appLog.debug("Returned \(stream.data?.count ?? 0) points for stream type \(stream.type!), series type \(stream.seriesType!)")
				_ = RVStream.create(stream: stream, activity: activity, context: context)
			}
			context.saveContext()
			completionHandler(true)

			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}
}

