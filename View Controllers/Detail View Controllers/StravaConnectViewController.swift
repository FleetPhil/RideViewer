//
//  StravaConnectViewController.swift
//  RideViewer
//
//  Created by Home on 24/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import StravaSwift

class StravaConnectViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		NotificationCenter.default.addObserver(self,
											   selector: #selector(self.performAuth(notification:)),
											   name: NSNotification.Name("code"),
											   object: nil)
	}

	
	@IBAction func connectButton(_ sender: Any) {
		StravaManager.sharedInstance.authorise()
	}
	
	@objc func performAuth( notification: NSNotification) {
		guard let code = notification.object as? String else { return }
		
		do {
			let _ = StravaManager.sharedInstance.getToken(code: code) { success in
				if success {
					appLog.debug("Have token")
//					StravaAuthorise.sharedInstance.updateActivities(page: 1)
				} else {
					appLog.debug("getToken failed")
				}
			}
		}
	}
	
}
