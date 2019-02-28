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
                    let context = CoreDataManager.sharedManager().persistentContainer.newBackgroundContext()
					StravaManager.sharedInstance.getAthleteActivities(page: 1, context: context, completionHandler: { newActivities in
						appLog.debug("\(newActivities) new activities")
					})
                    StravaManager.sharedInstance.getStarredSegments(page: 1, context: context, completionHandler: {
                        appLog.debug("Got starred segments")
                    })
				} else {
					appLog.debug("getToken failed")
				}
			}
		}
	}


	
}
