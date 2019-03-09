//
//  RVSplitViewController.swift
//  RideViewer
//
//  Created by Home on 08/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class RVSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

		self.delegate = self
		self.preferredDisplayMode = .allVisible
    }
	
	func splitViewController(_ splitViewController: UISplitViewController,
							 collapseSecondary secondaryViewController: UIViewController,
							 onto primaryViewController: UIViewController) -> Bool {
		if self.traitCollection.horizontalSizeClass == .compact {
			return true
		} else {
			return false
		}
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		var displayString = "H: "
		switch traitCollection.horizontalSizeClass {
		case .compact:		displayString += "Compact"
		case .regular:		displayString += "Regular"
		case .unspecified:	displayString += "Unspecified"
		}
		displayString += ", V: "
		switch traitCollection.verticalSizeClass {
		case .compact:		displayString += "Compact"
		case .regular:		displayString += "Regular"
		case .unspecified:	displayString += "Unspecified"
		}
		appLog.debug(displayString)
	}
}
