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
	
	// Static values
	let streamTypesForActivity = "distance,altitude"
	let streamTypesForEffort   = "watts,heartrate,time,cadence"
	
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
					self?.token = nil
				}
			}
		} catch (let error) {
			appLog.error("Strava token error \(error)")
			self.token = nil
			completion(false)
		}
	}
	
	var haveToken : Bool {
		return token != nil
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
			
			appLog.verbose("Retrieved activity details for \(activity.name ?? "None?")")
			let _ = RVActivity.create(activity: activity, context: context)
			completionHandler(true)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	// TODO: only call completion handler when all data is retrieved
    func getStarredSegments (page : Int, context : NSManagedObjectContext, completionHandler : @escaping (([RVSegment])->Void)) {
        let params = ["per_page":100, "page":page]
		var starredSegments: [RVSegment] = []
        
        try? StravaClient.sharedInstance.request(Router.segmentsStarred(params: params), result: { [weak self] (segments: [Segment]?) in
            guard let `self` = self, let segments = segments else { return }
            
            appLog.debug("Retrieved \(segments.count) starred segments for page \(page)")
            if segments.count > 0 {
                segments.forEach {
                    let createdSegment = RVSegment.create(segment: $0, context: context)
					if createdSegment.streams.count == 0 {
						self.streamsForSegment(createdSegment, context: context, completionHandler: { success in
							appLog.verbose("Got \(createdSegment.streams.count) streams for \(createdSegment.name!)")
						})
					}
					starredSegments.append(createdSegment)
                }
            }
            if segments.count == 100 {
                self.getStarredSegments(page: page + 1, context: context, completionHandler: completionHandler)        // get next page
            } else {
                // No more segments to load
                completionHandler(starredSegments)
            }
        }, failure: { (error: NSError) in
            debugPrint(error)
        })
    }
	
	func getSegment(_ segment : RVSegment, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
		guard token != nil else {
			completionHandler(false)
			return
		}
		
		try? StravaClient.sharedInstance.request(Router.segments(id: Router.Id(segment.id), params: [:]), result: { (newSegment: Segment?) in
			guard let segment = newSegment else { return }
			
			let _ = RVSegment.create(segment: segment, context: context)
			completionHandler(true)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	func effortsForSegment(_ segment : RVSegment, page : Int, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
		guard token != nil else { return }
		
		if segment.allEfforts {
			appLog.debug("Efforts called but already have them")
		}
		
		try? StravaClient.sharedInstance.request(Router.segmentsEfforts(id: Router.Id(segment.id), params: ["page":page, "per_page" : 100]), result: { (efforts : [Effort]?) in
			guard let efforts = efforts else {
				completionHandler(false)
				return
			}
			
			if efforts.count > 0 {
				efforts.forEach {
					if let activityID = $0.activity?.id {
						let _ = RVEffort.create(effort: $0, forActivity: RVActivity.get(identifier: activityID, inContext: context)!, context: context)
					}
				}
                appLog.verbose("\(efforts.count) efforts for \(efforts.first!.segment!.name!) on page \(page)")
                segment.allEfforts = true
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
		guard token != nil else {
			completionHandler(false)
			return			
		}
		
		try? StravaClient.sharedInstance.request(Router.activityStreams(id: Router.Id(activity.id), types: streamTypesForActivity), result: { (streams : [StravaSwift.Stream]?) in
			streams?.forEach { _ = RVStream.createForActivity(activity, stream: $0, context: context) }
			completionHandler(streams != nil ? true : false)
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}
	
	func streamsForSegment(_ segment : RVSegment, context: NSManagedObjectContext, completionHandler: @escaping ((Bool)->Void)) {
		guard token != nil else { return }
		
		try? StravaClient.sharedInstance.request(Router.segmentStreams(id: Router.Id(segment.id), types: streamTypesForActivity), result: { (streams : [StravaSwift.Stream]?) in
			streams?.forEach { _ = RVStream.createForSegment(segment, stream: $0, context: context) }
			completionHandler(streams != nil ? true : false)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	func streamsForEffort(_ effort : RVEffort, context: NSManagedObjectContext, completionHandler: @escaping ((Bool)->Void)) {
		guard token != nil else { return }
		
		try? StravaClient.sharedInstance.request(Router.effortStreams(id: Router.Id(effort.id), types: streamTypesForEffort), result: { (streams : [StravaSwift.Stream]?) in
			streams?.forEach { _ = RVStream.createForEffort(effort, stream: $0, context: context) }
			completionHandler(streams != nil ? true : false)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
}

