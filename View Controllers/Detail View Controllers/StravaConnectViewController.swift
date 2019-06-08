//
//  StravaConnectViewController.swift
//  RideViewer
//
//  Created by Home on 24/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import StravaSwift
import CoreData

class StravaConnectViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	@IBAction func connectButton(_ sender: Any) {
        let context = CoreDataManager.sharedManager().viewContext
        if let effort : RVEffort = context.fetchObject(withKeyValue: 47430602395, forKey: "id") {
            let streamHR = effort.streamOfType(.heartRate)!.dataPoints
            let streamTime = effort.streamOfType(.time)!.dataPoints
            let streamCum = effort.streamOfType(.cumulativeHR)!.dataPoints
            
            appLog.debug("HR: \(streamHR)")
            appLog.debug("Time: \(streamTime)")
            appLog.debug("Cum: \(streamCum)")
            
        } else {
            appLog.error("Effort not found")
        }
    }
	
}
