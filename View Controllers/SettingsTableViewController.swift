//
//  SettingsTableViewController.swift
//  RideViewer
//
//  Created by Home on 02/01/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

extension Notification.Name {
	static let didChangeActivitySettings = Notification.Name("didChangeActivitySettings")
	static let didChangeSegmentSettings = Notification.Name("didChangeSegmentSettings")
}

class SettingsTableViewController: UITableViewController {
	
	private enum switchTag : Int {
		case includeVirtual = 1
		case onlyBike = 2
		case onlyMeter = 3
	}
	private enum stepperTag : Int {
		case activityMin = 1
		case segmentMin = 2
	}
	
	private var activityChanged : Bool = false
	private var segmentChanged : Bool = false
	
	@IBOutlet weak var activityMinText: UILabel!
	@IBOutlet weak var segmentMinText: UILabel!
	@IBOutlet weak var includeVirtual: UISwitch!
	@IBOutlet weak var onlyBike: UISwitch!
	@IBOutlet weak var onlyMeter: UISwitch!
	@IBOutlet weak var activityStepper: UIStepper!
	@IBOutlet weak var segmentStepper: UIStepper!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationItem.title = "Settings"
		
		setDisplayValues()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		if activityChanged {
			NotificationCenter.default.post(name: .didChangeActivitySettings, object: nil)
		}
		if segmentChanged {
			NotificationCenter.default.post(name: .didChangeSegmentSettings, object: nil)
		}
	}
	
	func setDisplayValues() {
		// Set values from setting shared object
		self.includeVirtual.isOn		= Settings.sharedInstance.includeVirtual
		self.onlyBike.isOn				= Settings.sharedInstance.onlyBike
		self.onlyMeter.isOn				= Settings.sharedInstance.onlyMeter
		
		self.activityStepper.value		= Settings.sharedInstance.activityMinDistance
		self.segmentStepper.value		= Settings.sharedInstance.segmentMinDistance
		
		self.activityMinText.text		= "Only show activities at least \(Settings.sharedInstance.activityMinDistance.distanceDisplayString)"
		self.segmentMinText.text		= "Only show segments at least \(Settings.sharedInstance.segmentMinDistance.distanceDisplayString)"
	}
	

	@IBAction func settingsSwitch(_ sender: Any) {
		if let settingsSwitch = sender as? UISwitch {
			switch settingsSwitch.tag {
			case switchTag.includeVirtual.rawValue :	Settings.sharedInstance.includeVirtual = settingsSwitch.isOn	; activityChanged = true
			case switchTag.onlyBike.rawValue :			Settings.sharedInstance.onlyBike = settingsSwitch.isOn			; activityChanged = true
			case switchTag.onlyMeter.rawValue :			Settings.sharedInstance.onlyMeter = settingsSwitch.isOn			; activityChanged = true ; segmentChanged = true
			default: 									appLog.error("Unexpected tag \(settingsSwitch.tag)")
			}
			setDisplayValues()
		} else {
			appLog.error("Not switch?")
		}
		
	}
	
	@IBAction func settingsStepper(_ sender: Any) {
		if let stepper = sender as? UIStepper {
			switch stepper.tag {
			case stepperTag.activityMin.rawValue:		Settings.sharedInstance.activityMinDistance = stepper.value		; activityChanged = true
			case stepperTag.segmentMin.rawValue:		Settings.sharedInstance.segmentMinDistance = stepper.value		; segmentChanged = true
			default: 									appLog.error("Unexpected tag \(stepper.tag)")
			}
			setDisplayValues()
		} else {
			appLog.error("Not stepper?")
		}
	}
	
}
