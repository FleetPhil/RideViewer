//
//  BasePickerPopoverViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 19/08/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

open class BasePickerPopoverViewController: UIViewController {
    
    /// AbstractPopover
    var anyPopover: BasePicker!
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setPopoverProperties()
    }
    
    /// Make the popover property reflect on the popover
    func setPopoverProperties() {
        title = anyPopover.title
    }
}

extension BasePickerPopoverViewController: UIPopoverPresentationControllerDelegate {
    /// Popover appears on iPhone
    open func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    open func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        guard let allowed = anyPopover.isAllowedOutsideTappingDismissing else {
            return true
        }
        return allowed
    }
}
