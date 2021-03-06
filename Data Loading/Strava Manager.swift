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

enum StravaStatus {
    case connecting
    case connected
    case connectFailed
    case stravaFailure(Error)
    case getStats
    case athleteStats(Int)              // Activity total
    case newActivities(Int)             // Number of new activities retrieved
    case updatingActivities(Int)        // Number retrieved
    case updateComplete                 //
    
    var statusText : String {
        switch self {
        case .connecting:                               return "Connecting to Strava"
        case .connected:                                return "Connected to Strava"
        case .connectFailed:                            return "Strava connection failed"
        case .stravaFailure(let error):                 return "Strava error: \(error.localizedDescription)"
        case .getStats:                                 return "Getting athlete details"
        case .athleteStats(let activityCount):          return "\(activityCount) total activities"
        case .newActivities(let activityCount):         return "Got \(activityCount) new activities"
        case .updatingActivities(let activityCount):    return "Updated \(activityCount) activities"
        case .updateComplete:                           return "Update complete"
        }
    }
    
}

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
    private var athlete : Athlete?
    private var athleteStats : AthleteStats?
    
	private var lastActivityDate : Date? = nil
	
	private init () {
		let config = StravaConfig(clientId: StravaConstants.ClientID,
								  clientSecret: StravaConstants.ClientSecret,
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
			try strava.getAccessToken(code) { returnedToken in
				if let validToken = returnedToken {
                    appLog.debug("Got token: \(self.token.accessToken!), \(String(describing: self.token.refreshToken))")
                    self.token = validToken
                    self.token.save()
                    completion(true)
				} else {
					// Async
					appLog.debug("Async return")
					self.token = nil
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
	
	// MARK: Strava Data Retrieval functions
    private func getAthlete(completionHandler : @escaping (Error?)->Void) {
        try? StravaClient.sharedInstance.request(Router.athlete, result: { (athlete : Athlete?) in
            self.athlete = athlete
            self.getAthleteStats(completionHandler: { (success) in
                completionHandler(nil)
                })
        }, failure: { (error: NSError) in
            appLog.error(error)
            completionHandler(error)
        })
    }
    
    // Get athlete stats
    private func getAthleteStats(completionHandler : @escaping (Error?)->Void)  {
        try? StravaClient.sharedInstance.request(Router.athletesStats(id: self.athlete!.id!, params: ["page": 1]), result: { (stats : AthleteStats?) in
            appLog.debug("Got stats")
            self.athleteStats = stats
            completionHandler(nil)
        }, failure: { (error: NSError) in
            appLog.error(error)
            completionHandler(error)
        })
    }
    
    // Update the connected athlete activities and get all activity details
    func refreshAthlete(context: NSManagedObjectContext, progressHandler: @escaping ((StravaStatus)->Void)) {
        guard haveToken else {
            progressHandler(.connectFailed)
            return
        }
        getAthlete(completionHandler: { (error) in
            guard error == nil else {
                progressHandler(.stravaFailure(error!))
                return
            }
            // Have athlete stats
            progressHandler(.athleteStats(self.athleteStats?.allRideTotals?.count ?? 0))
            })
    }
    
	// Get a page of activities
	func getAthleteActivities(page : Int, context : NSManagedObjectContext, progressHandler : @escaping ((_ newActivity : RVActivity?, _ finished : Bool)->Void)) {
		var params = ["per_page":StravaConstants.ItemsPerPage, "page":page]

		if page == 1 {
		// Get time of latest activity and save the date 
			if let activities : [RVActivity] = context.fetchObjects() {
				if activities.count > 0 {
                    self.lastActivityDate = activities.map({ $0.startDate as Date }).max()
				}
			}
		}
		
        if self.lastActivityDate != nil {
			params["after"] = Int(self.lastActivityDate!.timeIntervalSince1970)
		}
		
		try? StravaClient.sharedInstance.request(Router.athleteActivities(params: params), result: { (activities: [Activity]?) in
			guard let activities = activities else { return }
			
			appLog.debug("Retrieved \(activities.count) activities for page \(page)")
			if activities.count > 0 {
				activities.forEach {
					let newActivity = RVActivity.create(activity: $0, context: context)
					progressHandler(newActivity, false)
				}
				// Get next page
                self.getAthleteActivities(page: page + 1, context: context, progressHandler: progressHandler)		// get next page
			} else {
				// No more activities to load
				self.lastActivityDate = nil
                progressHandler(nil, true)
			}
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}
	
	// Get details for specified activity
    func getDetailedActivity(_ activity : RVActivity, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
		guard token != nil else {
            completionHandler(false)
            return
        }
		
		try? StravaClient.sharedInstance.request(Router.activities(id: Router.Id(activity.id), params: ["include_all_efforts":false]), result: { (activities: Activity?) in
			guard let activity = activities else {
                completionHandler(false)
                return
            }
			
			appLog.verbose("Have detailed for \(activity.name ?? "None?")")
			let _ = RVActivity.create(activity: activity, context: context)
			completionHandler(true)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
    
    

	
	// TODO: only call completion handler when all data is retrieved
    func getStarredSegments (page : Int, context : NSManagedObjectContext, completionHandler : @escaping (([RVSegment])->Void)) {
        let params = ["per_page":StravaConstants.ItemsPerPage, "page":page]
		var starredSegments: [RVSegment] = []
        
        try? StravaClient.sharedInstance.request(Router.segmentsStarred(params: params), result: { [weak self] (segments: [Segment]?) in
            guard let `self` = self, let segments = segments else { return }
            
            appLog.debug("Retrieved \(segments.count) starred segments for page \(page)")
            if segments.count > 0 {
                segments.forEach {
                    let createdSegment = RVSegment.create(segment: $0, context: context)
					if createdSegment.resourceState != .detailed {
						self.getSegmentDetails(createdSegment, context: context, completionHandler: { success in
							appLog.debug("Got detailed: \(createdSegment.name!)")
						})
					}
					
					if createdSegment.streams.count == 0 {
						self.streamsForSegment(createdSegment, context: context, completionHandler: { success in
							appLog.verbose("Got \(createdSegment.streams.count) streams for \(createdSegment.name!)")
						})
					}
					starredSegments.append(createdSegment)
                }
            }
            if segments.count == StravaConstants.ItemsPerPage {
                self.getStarredSegments(page: page + 1, context: context, completionHandler: completionHandler)        // get next page
            } else {
                // No more segments to load
                completionHandler(starredSegments)
            }
        }, failure: { (error: NSError) in
            debugPrint(error)
        })
    }
	
	func getSegmentDetails(_ segment : RVSegment, context : NSManagedObjectContext, completionHandler : @escaping ((Bool)->Void)) {
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
		guard token != nil else {
            completionHandler(false)
            return
        }
		
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
				completionHandler(true)
			} else {			// Finished
				// We have all current efforts for this segment
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
		
		try? StravaClient.sharedInstance.request(Router.activityStreams(id: Router.Id(activity.id), types: StravaStreamType.Activity), result: { (streams : [StravaSwift.Stream]?) in
			streams?.forEach({ RVStream.createWithStrava(owner: activity, stream: $0, context: context) })
			completionHandler(streams != nil ? true : false)
			}, failure: { (error: NSError) in
				debugPrint(error)
		})
	}
	
	func streamsForSegment(_ segment : RVSegment, context: NSManagedObjectContext, completionHandler: @escaping ((Bool)->Void)) {
		guard token != nil else {
			completionHandler(false)
			return
		}
		
		try? StravaClient.sharedInstance.request(Router.segmentStreams(id: Router.Id(segment.id), types: StravaStreamType.Activity), result: { (streams : [StravaSwift.Stream]?) in
			streams?.forEach({ RVStream.createWithStrava(owner: segment, stream: $0, context: context) })
			completionHandler(streams != nil ? true : false)
		}, failure: { (error: NSError) in
			debugPrint(error)
		})
	}
	
	func streamsForEffort(_ effort : RVEffort, context: NSManagedObjectContext, completionHandler: @escaping ((Bool)->Void)) {
		guard token != nil else {
			completionHandler(false)
			return
		}
		
		try? StravaClient.sharedInstance.request(Router.effortStreams(id: Router.Id(effort.id), types: StravaStreamType.Effort), result: { (streams : [StravaSwift.Stream]?) in
			streams?.forEach({ RVStream.createWithStrava(owner: effort, stream: $0, context: context) })
            // Create a gearRatio stream
			if let speedStream = streams?.filter({ $0.type == .velocitySmooth }).first, let cadenceStream = streams?.filter({ $0.type == .cadence }).first {
				RVStream.createWithData(owner: effort,
										type: .gearRatio,
										seriesType: speedStream.seriesType ?? "",
										originalSize: speedStream.originalSize ?? 0,
										data: self.gearStreamData(speed: speedStream, cadence: cadenceStream),
										context: context)
			}
            // Create a cumulative power stream
            if let powerStream = streams?.filter({ $0.type == .watts }).first,
                let powerValues = powerStream.data as? [Double],
                let timeStream = streams?.filter({ $0.type == .time }).first,
                let timeValues = timeStream.data as? [Double] {
                let timeDiffs = [0] + zip(timeValues.dropFirst(), timeValues).map(-)
                RVStream.createWithData(owner: effort,
                                        type: .cumulativePower,
                                        seriesType: powerStream.seriesType ?? "",
                                        originalSize: powerStream.originalSize ?? 0,
                                        data: powerValues.enumerated().map({ $0.element * timeDiffs[$0.offset] } ).reduce(into: []) { $0.append(($0.last ?? 0) + $1) },
                                        context: context)
            }
            // Create a cumulative heart rate stream
            if let hrStream = streams?.filter({ $0.type == .heartRate }).first,
                let hrValues = hrStream.data as? [Double],
                let timeStream = streams?.filter({ $0.type == .time }).first,
                let timeValues = timeStream.data as? [Double] {
                let timeDiffs = [0] + zip(timeValues.dropFirst(), timeValues).map(-)
                RVStream.createWithData(owner: effort,
                                        type: .cumulativeHR,
                                        seriesType: hrStream.seriesType ?? "",
                                        originalSize: hrStream.originalSize ?? 0,
                                        data: hrValues.enumerated().map({ ($0.element * timeDiffs[$0.offset]) / 60 } ).reduce(into: []) { $0.append(($0.last ?? 0) + $1) },
                                        context: context)
            }

            
			completionHandler(true)
		}, failure: { (error: NSError) in
			debugPrint(error)
			completionHandler(false)
		})
	}
	
	private func gearStreamData(speed: StravaSwift.Stream, cadence: StravaSwift.Stream) -> [Double] {
		guard let speedData = speed.data as? [Double], let cadenceData = cadence.data as? [Double] else { return [] }
		
		let x = speedData.enumerated().map { index, value in
			return cadenceData[index] == 0 ? 0.0 : value / cadenceData[index]
		}
		
		return x
	}
}

extension OAuthToken {

    func save() {
        UserDefaults.standard.set(self.accessToken, forKey: "StravaAccessToken")
        UserDefaults.standard.set(self.refreshToken, forKey: "StravaRefreshToken")
    }
    
    static func retrieve()->OAuthToken? {
        if let accessToken = UserDefaults.standard.object(forKey: "StravaAccessToken") {
            return OAuthToken(access: accessToken as? String, refresh: UserDefaults.standard.object(forKey: "StravaRefreshToken") as? String)
        } else {
            appLog.debug("Failed to retrieve token")
            return nil
        }
    }
}

