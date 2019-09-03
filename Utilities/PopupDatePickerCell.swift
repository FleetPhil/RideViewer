//
//  PopupDatePickerCell.swift
//  RideViewer
//
//  Created by West Hill Lodge on 18/07/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class PopupBoolPickerCell: UITableViewCell {
    var cellValue : Bool = false
    
    func setValueForItem(_ cellValue: PopupItem) {
        guard case .typeBool(let value) = cellValue.value else { return }
        self.textLabel?.text = cellValue.label
        
        self.cellValue = value
        if value == true {
            self.accessoryType = .checkmark
        } else {
            self.accessoryType = .none
        }
    }
    
    var value : Bool {
        return self.cellValue
    }
}

class PopupDatePickerCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    func setValueForItem(_ cellValue: PopupItem) {
        guard case .typeDate(let value) = cellValue.value else { return }

        dateLabel.text = cellValue.label
        datePicker.date = value
    }
    
    var value : Date {
        return datePicker.date
    }
}

class PopupRangePickerCell : UITableViewCell {
    @IBOutlet weak var rangeLabel: UILabel!
    @IBOutlet weak var rangePicker : UISlider!
    
    func setValueForItem(_ cellValue : PopupItem) {
        guard case .typeRange(let value) = cellValue.value else { return }

        rangeLabel.text = cellValue.label
        rangePicker.setValue(Float(value.from), animated: false)
    }
    
    var value : Float {
        return rangePicker.value
    }
}
