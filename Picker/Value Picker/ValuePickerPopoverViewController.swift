//
//  ValuePickerPopoverViewController.swift
//  PickerTest
//
//  Created by West Hill Lodge on 02/09/2019.
//  Copyright © 2019 FleetPhil. All rights reserved.
//

import Foundation
import UIKit

class ValuePickerPopoverViewController : BasePickerPopoverViewController {
    
    typealias PopoverType = ValuePicker
    
    fileprivate var popover: PopoverType! { return anyPopover as? PopoverType }
    
    @IBOutlet weak private var picker: UISlider!
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
        
        picker.minimumValue = Float(popover.lowLimit)
        picker.maximumValue = Float(popover.highLimit)

        picker.value = Float(popover.selectedValue)
    }
    
    @IBAction func tappedDone(_ sender: UIBarButtonItem) {
        tapped(button: popover.doneButton)
    }
    
    @IBAction func tappedCancel(_ sender: UIBarButtonItem? = nil) {
        tapped(button: popover.cancelButton)
    }
    
    private func tapped(button: ValuePicker.ButtonParameterType?) {
        button?.action?(popover, Double(picker.value))
        dismiss(animated: false)
    }
    
    func pickerValueChanged(_ sender: UIDatePicker) {
        popover.valueChangeAction?(popover, Double(picker!.value))
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        tappedCancel()
    }
}
