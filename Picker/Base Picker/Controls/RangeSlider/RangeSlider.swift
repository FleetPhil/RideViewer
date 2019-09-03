import UIKit
import QuartzCore

class RangeSlider: UIControl {
    private let trackLayer = RangeSliderTrackLayer()
    private let lowerThumbLayer = RangeSliderThumbLayer()
    private let upperThumbLayer = RangeSliderThumbLayer()
    private var previousLocation = CGPoint()

    var minimumValue: Double = 0.0 {
        didSet {
            updateLayerFrames()
        }
    }

    var maximumValue: Double = 1.0 {
        didSet {
            updateLayerFrames()
        }
    }

    var lowerValue: Double = 0.2 {
        didSet {
            lowerThumbLayer.thumbValue = thumbText(lowerValue)
            updateLayerFrames()
        }
    }

    var upperValue: Double = 0.8 {
        didSet {
            upperThumbLayer.thumbValue = thumbText(upperValue)
            updateLayerFrames()
        }
    }

    var trackTintColor: UIColor = UIColor(white: 0.9, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }

    var trackHighlightTintColor: UIColor = UIColor(red: 0.0, green: 0.45, blue: 0.94, alpha: 1.0) {
        didSet {
            trackLayer.setNeedsDisplay()
        }
    }

    var thumbTintColor: UIColor = UIColor.white {
        didSet {
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    var curvaceousness: CGFloat = 1.0 {
        didSet {
            trackLayer.setNeedsDisplay()
            lowerThumbLayer.setNeedsDisplay()
            upperThumbLayer.setNeedsDisplay()
        }
    }

    var thumbWidth: CGFloat {
        return CGFloat(bounds.height)
    }

    /// Convert double value into text for thumb, return nil to not show text
    var thumbText: ((Double)->String?) = { _ in return nil }

    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    override func layoutSubviews() {
        updateLayerFrames()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSlider()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupSlider()
    }
    
    private func setupSlider() {
        trackLayer.rangeSlider = self
        trackLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(trackLayer)
        
        lowerThumbLayer.rangeSlider = self
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)
        
        upperThumbLayer.rangeSlider = self
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(upperThumbLayer)
        
    }
    
    private func updateLayerFrames() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let trackLayerHeight : CGFloat = 2.0
        trackLayer.frame = CGRect(x: 0.0, y: bounds.midY - trackLayerHeight / 2, width: bounds.width, height: trackLayerHeight)
        trackLayer.setNeedsDisplay()

        let lowerThumbCenter = CGFloat(positionForValue(value: lowerValue))

        lowerThumbLayer.frame = CGRect(x: lowerThumbCenter - thumbWidth / 2.0, y: 0.0, width: thumbWidth, height: thumbWidth)
        lowerThumbLayer.setNeedsDisplay()

        let upperThumbCenter = CGFloat(positionForValue(value: upperValue))
        upperThumbLayer.frame = CGRect(x: upperThumbCenter - thumbWidth / 2.0, y: 0.0,
            width: thumbWidth, height: thumbWidth)
        upperThumbLayer.setNeedsDisplay()

        CATransaction.commit()
    }

    func positionForValue(value: Double) -> Double {
        return Double(bounds.width - thumbWidth) * (value - minimumValue) /
            (maximumValue - minimumValue) + Double(thumbWidth / 2.0)
    }

    // Touch handlers
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        previousLocation = touch.location(in: self)
        
        // Hit test the thumb layers
        if lowerThumbLayer.frame.contains(previousLocation) {
            lowerThumbLayer.highlighted = true
        } else if upperThumbLayer.frame.contains(previousLocation) {
            upperThumbLayer.highlighted = true
        }
        
        return lowerThumbLayer.highlighted || upperThumbLayer.highlighted
    }

    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double {
        return min(max(value, lowerValue), upperValue)
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        // 1. Determine by how much the user has dragged
        let deltaLocation = Double(location.x - previousLocation.x)
        let deltaValue = (maximumValue - minimumValue) * deltaLocation / Double(bounds.width - bounds.height)

        previousLocation = location

        // 2. Update the values
        if lowerThumbLayer.highlighted {
            let newValue = lowerValue + deltaValue
            lowerValue = boundValue(value: newValue, toLowerValue: minimumValue, upperValue: upperValue)
        } else if upperThumbLayer.highlighted {
            let newValue = upperValue + deltaValue
            upperValue = boundValue(value: newValue, toLowerValue: lowerValue, upperValue: maximumValue)
        }

        sendActions(for: .valueChanged)
        
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        lowerThumbLayer.highlighted = false
        upperThumbLayer.highlighted = false
    }
    
}
