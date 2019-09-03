//
//  ValueSlider.swift
//  PickerTest
//
//  Created by West Hill Lodge on 02/09/2019.
//  Copyright © 2019 FleetPhil. All rights reserved.
//

import Foundation
import UIKit

class ValueSlider: UISlider {
    let label = UILabel()
 
    override func layoutSubviews() {
        super.layoutSubviews()
        self.addSubview(label)
        showValueLabel()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let track = super.beginTracking(touch, with: event)
        self.addSubview(label)
        showValueLabel()
        return track
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let track = super.continueTracking(touch, with: event)
        showValueLabel()
        return track
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        label.removeFromSuperview()
    }
    
    private func showValueLabel() {
        label.frame = self.thumbRect(forBounds: bounds, trackRect: bounds, value: value)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "\(Int(self.value))"
    }
}
