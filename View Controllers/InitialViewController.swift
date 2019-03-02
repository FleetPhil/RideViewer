//
//  InitialViewController.swift
//  RideViewer
//
//  Created by Home on 21/02/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class InitialViewController: UIViewController {
	
	@IBOutlet weak var connectButton: UIButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.performAuth(notification:)),
											   name: NSNotification.Name("code"),
											   object: nil)
		showStats()

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
					
					StravaManager.sharedInstance.getAthleteActivities(page: 1, context: context, completionHandler: { newActivities in
						appLog.debug("\(newActivities) new activities - getting starred segments")
						StravaManager.sharedInstance.getStarredSegments(page: 1, context: context, completionHandler: {
							appLog.debug("Got starred segments")
							self.showStats()
						})
					})
					
				} else {
					appLog.debug("getToken failed")
				}
			}
		}
	}
	
	func showStats() {
		appLog.debug("\(CoreDataManager.sharedManager().viewContext.countOfObjects(RVActivity.self) ?? -1) activities")
		appLog.debug("\(CoreDataManager.sharedManager().viewContext.countOfObjects(RVSegment.self) ?? -1) segments")
		appLog.debug("\(CoreDataManager.sharedManager().viewContext.countOfObjects(RVEffort.self) ?? -1) efforts")
		appLog.debug("\(CoreDataManager.sharedManager().viewContext.countOfObjects(RVStream.self) ?? -1) streams")
	}
}
