//
//  StringPicker.swift
//  RideViewer
//
//  Created by West Hill Lodge on 19/08/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

open class StringPicker: BasePicker {
    // MARK: Types
    
    /// Type of choice value
    public typealias ItemType = String
    /// Popover type
    public typealias PopoverType = StringPicker
    /// Action type for buttons
    public typealias ActionHandlerType = (PopoverType, Int, ItemType) -> ()
    /// Button parameters type
    public typealias ButtonAction = ActionHandlerType?
    /// Type of the rule closure to convert from a raw value to the display string
    public typealias DisplayStringForType = ((ItemType?)->String?)
    
    // MARK: - Properties
    
    /// Choice array
    private(set) var choices: [ItemType] = []
    /// Array of image to attach to a choice
    private(set) var images: [UIImage?]?
    
    /// Convert a raw value to the string for displaying it
    private(set) var displayStringFor: DisplayStringForType?
    
    /// Done button parameters
    private(set) var doneButtonAction: ButtonAction = nil
    /// Cancel button parameters
    private(set) var cancelButtonAction: ButtonAction = nil
    
    /// Action for picker value change
    private(set) var valueChangeAction: ActionHandlerType?
    
    /// Selected row
    private(set) var selectedRow: Int = 0
    
    /// Row height
    private(set) var rowHeight: CGFloat = 44
    
    // MARK: - Initializer
    
    /// Initialize a Popover with the following arguments.
    ///
    /// - Parameters:
    ///   - title: Title for navigation bar.
    ///   - choices: Options for picker.
    public init(title: String?, choices: [ItemType]) {
        super.init()
        
        // Set parameters
        self.title = title
        self.choices = choices
    }
    
    /// Set selected row
    ///
    /// - Parameter row: Selected row on picker
    /// - Returns: Self
    public func setSelectedRow(_ row: Int) -> Self {
        self.selectedRow = row
        return self
    }
    
    /// Set displayStringFor closure
    ///
    /// - Parameter displayStringFor: Rules for converting choice values to display strings.
    /// - Returns: Self
    public func setDisplayStringFor(_ displayStringFor: DisplayStringForType?) -> Self {
        self.displayStringFor = displayStringFor
        return self
    }
    
    /// Set done button action
    ///
    /// - Parameters:
    ///   - action: Action to be performed before the popover disappeared. The popover, Selected row, Selected value.
    /// - Returns: Self
    public func setDoneButtonAction(_ action: ActionHandlerType?) -> Self {
        doneButtonAction = action
        return self
    }
    
    /// Set cancel button action
    ///
    /// - Parameters:
    ///   - action: Action to be performed before the popover disappeared.The popover, Selected row, Selected value.
    /// - Returns: Self
    public func setCancelButtonAction(_ action: ActionHandlerType?) -> Self {
        cancelButtonAction = action
        return self
    }
    
    /// Set an action for each value change done by user
    ///
    /// - Parameters:
    ///   -action: Action to be performed each time the picker is moved to a new value.
    /// - Returns: Self
    public func setValueChange(action: ActionHandlerType?) -> Self{
        valueChangeAction = action
        return self
    }
}
