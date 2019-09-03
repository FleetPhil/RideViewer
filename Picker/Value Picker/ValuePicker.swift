//
//  ValuePicker.swift
//  PickerTest
//
//  Created by West Hill Lodge on 02/09/2019.
//  Copyright © 2019 FleetPhil. All rights reserved.
//

import Foundation
import UIKit

open class ValuePicker: BasePicker {
    
    // MARK: Types
    
    /// Type of choice value
    public typealias ItemType = Double
    /// Popover type
    public typealias PopoverType = ValuePicker
    /// Action type for buttons
    public typealias ActionHandlerType = (PopoverType, ItemType) -> Void
    /// Button parameters type
    public typealias ButtonParameterType = (title: String, font: UIFont?, color: UIColor?, action: ActionHandlerType?)
    
    // MARK: - Properties
    
    /// Done button parameters
    private(set) var doneButton: ButtonParameterType = (title: "Done", font: nil, color: nil, action: nil)
    /// Cancel button parameters
    private(set) var cancelButton: ButtonParameterType = (title: "Cancel", font: nil, color: nil, action: nil)
    /// Clear button parameters
    private(set) var clearButton: ButtonParameterType = (title: "Clear", font: nil, color: nil, action: nil)
    /// Action for picker value change
    private(set) var valueChangeAction: ActionHandlerType?
    
    /// Limit of range
    private(set) var lowLimit : Double = 0
    private(set) var highLimit : Double = 100
    /// Selected value
    private(set) var selectedValue: Double = 60
    
    // MARK: - Initializer
    
    /// Initialize a Popover with the following argument.
    ///
    /// - Parameter title: Title for navigation bar.
    public init(title: String?){
        super.init()
        self.title = title
    }
    
    // MARK: - Property setter
    
    /// Set selected value
    ///
    /// - Parameter row: The default value of picker.
    /// - Returns: self
    public func setSelectedValue(_ value:ItemType)->Self{
        self.selectedValue = value
        return self
    }
    
    /// Set range limit
    ///
    /// - Parameter limit: low and high limit
    /// - Returns: self
    public func setValueLimit(lowLimit: Double, highLimit: Double)->Self{
        self.lowLimit = lowLimit
        self.highLimit = highLimit
        return self
    }
    
    /// Set text function for buttons
    ///
    /// - Parameter function taking Double value and returning String for display on slider thumb
    /// - Returns: self
//    public func setThumbTextFunction(_ textFunction: @escaping (Double)->String?)->Self {
//        self.selectedRange.thumbDisplayFunction = textFunction
//        return self
//    }
    
    /// Set Done button properties
    ///
    /// - Parameters:
    ///   - title: Title for the bar button item. Omissible. If it is nil or not specified, then localized "Done" will be used. Omissible.
    ///   - font: Button title font. Omissible.
    ///   - color: Button tint color. Omissible. If this is nil or not specified, then the button tintColor inherits appear()'s baseViewController.view.tintColor.
    ///   - action: Action to be performed before the popover disappeared.
    /// - Returns: Self
    public func setDoneButton(title: String? = nil, font: UIFont? = nil, color: UIColor? = nil, action: ActionHandlerType?) -> Self{
        return setButton(button: &doneButton, title: title, font: font, color: color, action: action)
    }
    
    /// Set Cancel button properties
    ///
    /// - Parameters:
    ///   - title: Title for the bar button item. Omissible. If it is nil or not specified, then localized "Cancel" will be used. Omissible.
    ///   - font: Button title font. Omissible.
    ///   - color: Button tint color. Omissible. If this is nil or not specified, then the button tintColor inherits appear()'s baseViewController.view.tintColor.
    ///   - action: Action to be performed before the popover disappeared.
    /// - Returns: Self
    public func setCancelButton(title: String? = nil, font: UIFont? = nil, color: UIColor? = nil, action: ActionHandlerType?) -> Self{
        return setButton(button: &cancelButton, title: title, font: font, color: color, action: action)
    }
    
    /// Set button arguments to the targeted button propertoes
    ///
    /// - Parameters:
    ///   - button: Target button properties
    ///   - title: Button title
    ///   - font. Button title font
    ///   - color: Button tintcolor
    ///   - action: Action to be performed before the popover disappeared.
    /// - Returns: Self
    func setButton( button: inout ButtonParameterType, title: String? = nil, font: UIFont? = nil, color: UIColor? = nil, action: ActionHandlerType?) -> Self{
        if let t = title {
            button.title = t
        }
        if let font = font {
            button.font = font
        }
        if let c = color {
            button.color = c
        }
        button.action = action
        return self
    }
    
    /// Set an action for each value change done by user
    ///
    /// - Parameters:
    ///   -action: Action to be performed each time the picker is moved to a new value.
    /// - Returns: Self
    public func setValueChange(action: ActionHandlerType?)->Self{
        valueChangeAction = action
        return self
    }
}

