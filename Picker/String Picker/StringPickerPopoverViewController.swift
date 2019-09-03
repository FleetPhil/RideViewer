//
//  StringPickerPopoverViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 19/08/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class StringPickerPopoverViewController: BasePickerPopoverViewController {
    
    // MARK: Types
    
    /// Popover type
    typealias PopoverType = StringPicker
    
    // MARK: Properties
    
    /// Popover
    private var popover: PopoverType! { return anyPopover as? PopoverType }
    
    @IBOutlet weak private var cancelButton: UIBarButtonItem!
    @IBOutlet weak private var doneButton: UIBarButtonItem!
    @IBOutlet weak private var picker: UIPickerView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
    }
    
    /// Make the popover properties reflect on this view controller
    override func setPopoverProperties(){
        super.setPopoverProperties()
        // Select row if needed
        picker?.selectRow(popover.selectedRow, inComponent: 0, animated: true)
        
        // Set up cancel button
        if #available(iOS 11.0, *) { }
        else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    /// Action when tapping done button
    ///
    /// - Parameter sender: Done button
    @IBAction func tappedDone(_ sender: AnyObject? = nil) {
        tapped(buttonAction: popover.doneButtonAction)
    }
    
    /// Action when tapping cancel button
    ///
    /// - Parameter sender: Cancel button
    @IBAction func tappedCancel(_ sender: AnyObject? = nil) {
        tapped(buttonAction: popover.cancelButtonAction)
    }
    
    private func tapped(buttonAction: StringPicker.ButtonAction) {
        let selectedRow = picker.selectedRow(inComponent: 0)
        if let selectedValue = popover.choices[safe: selectedRow] {
            buttonAction?(popover, selectedRow, selectedValue)
        }
        dismiss(animated: false)
    }
    
    /// Action to be executed after the popover disappears
    ///
    /// - Parameter popoverPresentationController: UIPopoverPresentationController
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        tappedCancel()
    }
}

// MARK: - UIPickerViewDataSource
extension StringPickerPopoverViewController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return popover.choices.count
    }
}

// MARK: - UIPickerViewDelegate
extension StringPickerPopoverViewController: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let value: String = popover.choices[row]
        return popover.displayStringFor?(value) ?? value
    }
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let value: String = popover.choices[row]
        let adjustedValue: String = popover.displayStringFor?(value) ?? value
        let label: UILabel = view as? UILabel ?? UILabel()
        label.text = adjustedValue
        label.textAlignment = .center
        return label
    }
    
    public func pickerView(_ pickerView: UIPickerView,
                           rowHeightForComponent component: Int) -> CGFloat {
        return popover.rowHeight
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        popover.valueChangeAction?(popover, row, popover.choices[row])
    }
}



