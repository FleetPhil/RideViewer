//
//  InitialViewController.swift
//  RideViewer
//
//  Created by Home on 21/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData
import StravaSwift
import SwiftyJSON

class ConnectViewController: UIViewController {
	
	@IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    enum ConnectStatus : String {
        case checkingStrava = "Checking Strava"
        case connected      = "Connected to Strava"
        case noConnection   = "Strava not authorised"
        case getToken       = "Connecting to Strava"
        case auth           = "Authorising"
        case getActivities  = "Getting new activities"
        case getDetailed    = "Getting activity and segment details"
        case completed      = "Completed"
        case connectFail    = "Unable to get data from Strava"
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        // Hide the progress indicator and connect button for now
        progressView.isHidden = true
        connectButton.isHidden = true
        skipButton.isHidden = true
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.performAuth(notification:)),
											   name: NSNotification.Name("code"),
											   object: nil)
        
        
		
		//		showStats()
	}
	
	override func viewDidAppear(_ animated: Bool) {
        // Check to see if we have a valid authorisation token - if so go straight to the initial controller
        connectStatus(status: .checkingStrava)
        
        if isValidStravaToken() {
            // We have a valid token so segue to the initial screen
            connectStatus(status: .connected)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.performSegue(withIdentifier: "ShowInitialViewController", sender: self)
            }

        } else {
            // No valid token - show the connect button
            connectButton.isHidden = false
            skipButton.isHidden = false
            connectStatus(status: .noConnection)
        }
	}
    
    private func isValidStravaToken()->Bool {
        if let storedToken = OAuthToken.retrieve() {
            StravaManager.sharedInstance.set(storedToken)
            return true
        }
        // TODO: check if valid not expired
        return false
    }
    
    private func connectStatus(status: ConnectStatus) {
        progressLabel.text  = status.rawValue
        if status == .completed {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                self.progressLabel.isHidden = true
                self.progressView.isHidden = true
                self.performSegue(withIdentifier: "ShowInitialViewController", sender: self)
            }
        }
    }
	
	@IBAction func connectPressed(_ sender: UIButton) {
        progressLabel.isHidden = false
        connectStatus(status: .getToken)
		StravaManager.sharedInstance.authorise()
	}
	
	@objc func performAuth( notification: NSNotification) {
		guard let code = notification.object as? String else { return }
		
		do {
            connectStatus(status: .auth)
			let _ = StravaManager.sharedInstance.getToken(code: code) { [weak self] success in
				if success {
					self?.connectStatus(status: .getActivities)
					// Alamofire executes completion handler on the main queue so need to stay on main queue context here
					let context = CoreDataManager.sharedManager().viewContext
                    self?.getActivities(context: context)
				} else {
                    self?.connectStatus(status: .connectFail)
				}
			}
		}
    }
    
    private func getActivities(context: NSManagedObjectContext) {
        StravaManager.sharedInstance.getAthleteActivities(page: 1, context: context, progressHandler: { processedActivities, totalActivities, finished in
            if finished {
                // If new activities have been retrieved invalidate flags that indicate all efforts have been retrieved for each segment.
                // We don't know what segments are included on the new activities so need to invalidate all to be safe
                if totalActivities > 0 {
                    self.unsetAllEffortsFlags()
                }
                context.saveContext()
                self.connectStatus(status: .getDetailed)
                self.getDetailedActivities(context: context)
            } else {                    // Not finished
                
            }
        })
    }
    
    private func getDetailedActivities(context: NSManagedObjectContext) {
        guard let activities : [RVActivity] = context.fetchObjects() else {
            appLog.error("Failed to retrieve activities")
            return
        }
        let activityCount = Float(activities.count)
        var receivedCount : Float = 0.0
        progressView.isHidden = false
        progressView.setProgress(0.0, animated: false)
        
        activities.enumerated().forEach({ activity in
            activity.element.detailedActivity(completionHandler: { [weak self] detailedActivity in
                receivedCount += 1
                self?.progressView.setProgress(receivedCount/activityCount, animated: false)
                if receivedCount == activityCount {
                    self?.connectStatus(status: .completed)
                }
            })
        })
    }
	
	private func unsetAllEffortsFlags() {
		let predicate = NSPredicate(format: "allEfforts == %@", argumentArray: [NSNumber(value: true)])
		if let segments : [RVSegment] = CoreDataManager.sharedManager().viewContext.fetchObjects(withPredicate: predicate, withSortDescriptor: nil) {
			segments.forEach({ $0.allEfforts = false })
		}
	}
	
	// MARK: Stats
	
	private func showStats() {
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
}

