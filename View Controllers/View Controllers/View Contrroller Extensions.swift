//
//  View Contrroller Extensions.swift
//  RideViewer
//
//  Created by West Hill Lodge on 08/09/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    var activeController : UIViewController? {
        if let controller = self as? UINavigationController {
            return controller.topViewController
        } else {
            return self
        }
    }
    
    var detailViewController : UIViewController? {
        return self.splitViewController?.viewControllers.last?.activeController
    }
    
}


