//
//  InitialViewController.swift
//  RideViewer
//
//  Created by Home on 21/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData

class InitialViewController: UIViewController {
	
	@IBOutlet weak var connectButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.performAuth(notification:)),
											   name: NSNotification.Name("code"),
											   object: nil)
		
		//		showStats()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if StravaManager.sharedInstance.haveToken {
			connectButton.isEnabled = false
		}
	}
	
	@IBAction func connectPressed(_ sender: UIButton) {
		StravaManager.sharedInstance.authorise()
	}
	
	@objc func performAuth( notification: NSNotification) {
		guard let code = notification.object as? String else { return }
		
		do {
			let _ = StravaManager.sharedInstance.getToken(code: code) { success in
				if success {
					appLog.debug("Have token")
					// Alamofire executes completion handler on the main queue so need to stay on main queue context here
					let context = CoreDataManager.sharedManager().viewContext
					
					StravaManager.sharedInstance.getAthleteActivities(page: 1, context: context, progressHandler: { totalActivities, retrievedActivities, finished in
//						appLog.verbose("Progress: total: \(totalActivities), retrieved: \(retrievedActivities), finished: \(finished)")
						if finished {
							// Invalidate flags that indicate all efforts have been retrieved for each segment. We don't know what segments are included on the new activities
							// so need to invalidate all to be safe
							self.unsetAllEffortsFlags()
							
							StravaManager.sharedInstance.getStarredSegments(page: 1, context: context, completionHandler: { segments in
								appLog.debug("\(segments.count) segments - getting efforts and streams")
								self.effortsForSegments(segments, progressHandler: { total, processed, finished in
									appLog.verbose("Total Segments: \(total), Processed: \(processed), Finished: \(finished)")
									if finished {
										context.saveContext()
									}
								})
							})
						}
					})
				} else {
					appLog.debug("getToken failed")
				}
			}
		}
	}
	
	func unsetAllEffortsFlags() {
		let predicate = NSPredicate(format: "allEfforts == %@", argumentArray: [NSNumber(value: true)])
		if let segments : [RVSegment] = CoreDataManager.sharedManager().viewContext.fetchObjects(withPredicate: predicate, withSortDescriptor: nil) {
			segments.forEach({ $0.allEfforts = false })
		}
	}
	
	func showStats() {
		let activityRequest : NSFetchRequest<RVActivity> = RVActivity.fetchRequest()
		if let activities = try? CoreDataManager.sharedManager().viewContext.fetch(activityRequest) {
			var stateCounts = Dictionary(uniqueKeysWithValues: RVResourceState.allCases.map { ($0, 0) } )
			activities.forEach { activity in
				stateCounts[activity.resourceState] = stateCounts[activity.resourceState]! + 1
			}
			appLog.debug("\(activities.count) activities:")
			for count in stateCounts {
				appLog.debug("\(count.key.resourceStateName) : \(count.value)")
			}
		}
		let segmentRequest : NSFetchRequest<RVSegment> = RVSegment.fetchRequest()
		if let segments = try? CoreDataManager.sharedManager().viewContext.fetch(segmentRequest) {
			var stateCounts = Dictionary(uniqueKeysWithValues: RVResourceState.allCases.map { ($0, 0) } )
			segments.forEach { segment in
				stateCounts[segment.resourceState] = stateCounts[segment.resourceState]! + 1
			}
			appLog.debug("\(segments.count) segments:")
			for count in stateCounts {
				appLog.debug("\(count.key.resourceStateName) : \(count.value)")
			}
		}
		let effortRequest : NSFetchRequest<RVEffort> = RVEffort.fetchRequest()
		if let efforts = try? CoreDataManager.sharedManager().viewContext.fetch(effortRequest) {
			var stateCounts = Dictionary(uniqueKeysWithValues: RVResourceState.allCases.map { ($0, 0) } )
			efforts.forEach { effort in
				stateCounts[effort.resourceState] = stateCounts[effort.resourceState]! + 1
			}
			appLog.debug("\(efforts.count) efforts:")
			for count in stateCounts {
				appLog.debug("\(count.key.resourceStateName) : \(count.value)")
			}
		}
		appLog.debug("\(CoreDataManager.sharedManager().viewContext.countOfObjects(RVStream.self) ?? -1) streams")
	}
	
	func effortsForSegments(_ segments : [RVSegment], progressHandler : @escaping ((_ totalActivities : Int, _ processedActivities : Int, _ finished : Bool)->Void)) {
		var segmentsProcessedCount = 0
		segments.forEach { segment in
			if segment.allEfforts {
				// Already have all efforts for this segment
				segmentsProcessedCount += 1
				progressHandler(segments.count, segmentsProcessedCount, segments.count == segmentsProcessedCount)
			} else {
				StravaManager.sharedInstance.effortsForSegment(segment, page: 1, context: segment.managedObjectContext!, completionHandler: { success in
					if !success {
						appLog.debug("Efforts failed for segment \(segment.name!)")
					}
					segmentsProcessedCount += 1
					progressHandler(segments.count, segmentsProcessedCount, segments.count == segmentsProcessedCount)
				})
			}
		}
	}
}
