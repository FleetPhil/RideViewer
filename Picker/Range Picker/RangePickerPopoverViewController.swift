//
//  RangePickerPopoverViewController.swift
//  Picker
//
//  Created by West Hill Lodge on 31/08/2019.
//  Copyright © 2019 FleetPhil. All rights reserved.
//

import Foundation
import UIKit

class RangePickerPopoverViewController: BasePickerPopoverViewController {
    
    typealias PopoverType = RangePicker
    
    fileprivate var popover: PopoverType! { return anyPopover as? PopoverType }
    
    @IBOutlet weak private var picker: RangeSlider!
    @IBOutlet weak private var cancelButton: UIBarButtonItem!
    @IBOutlet weak private var doneButton: UIBarButtonItem!
    
    override func setPopoverProperties() {
        super.setPopoverProperties()
        if #available(iOS 11.0, *) { }
        else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        }
        cancelButton.title = popover.cancelButton.title
        navigationItem.setLeftBarButton(cancelButton, animated: false)
        
        doneButton.title = popover.doneButton.title
        navigationItem.setRightBarButton(doneButton, animated: false)
        
        picker.minimumValue = popover.limit.lowValue
        picker.maximumValue = popover.limit.highValue
        
        picker.thumbText    = popover.selectedRange.thumbDisplayFunction

        picker.lowerValue   = popover.selectedRange.lowValue
        picker.upperValue   = popover.selectedRange.highValue
        

    }
    
    @IBAction func tappedDone(_ sender: UIBarButtonItem) {
        tapped(button: popover.doneButton)
    }
    
    @IBAction func tappedCancel(_ sender: AnyObject? = nil) {
        tapped(button: popover.cancelButton)
    }
    
    private func tapped(button: RangePicker.ButtonParameterType?) {
        button?.action?(popover, RangePicker.PickerRange(lowValue: picker.lowerValue, highValue: picker.upperValue))
        dismiss(animated: false)
    }
    
    @IBAction func pickerValueChanged(_ sender: UIDatePicker) {
        popover.valueChangeAction?(popover, RangePicker.PickerRange(lowValue: picker.lowerValue, highValue: picker.upperValue))
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        tappedCancel()
    }
}

