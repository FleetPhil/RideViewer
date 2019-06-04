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
        
        // Hide the connect button for now
        connectButton.isHidden = true
        skipButton.isHidden = true
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.performAuth(notification:)),
											   name: NSNotification.Name("code"),
											   object: nil)
        
        
		
		//		showStats()
	}
	
	override func viewDidAppear(_ animated: Bool) {
        // Check to see if we have a valid authorisation token - if so go straight to the refresh controller
        
        if isValidStravaToken() {
            // We have a valid token so segue to the initial screen
            self.performSegue(withIdentifier: "ConnectToRefresh", sender: self)

        } else {
            // No valid token - show the connect button
            connectButton.isHidden = false
            skipButton.isHidden = false
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
	
	@IBAction func connectPressed(_ sender: UIButton) {
		StravaManager.sharedInstance.authorise()
	}
	
	@objc func performAuth( notification: NSNotification) {
		guard let code = notification.object as? String else { return }
		
		do {
			let _ = StravaManager.sharedInstance.getToken(code: code) { [weak self] success in
				if success {
                    // Segue to refresh controller
                    self?.performSegue(withIdentifier: "ConnectToRefresh", sender: self)
				} else {
				}
			}
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

