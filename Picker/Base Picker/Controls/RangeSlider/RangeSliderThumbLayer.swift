import UIKit
import QuartzCore

class RangeSliderThumbLayer: CALayer {
    
    var highlighted: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var thumbValue: String? = nil {
        didSet {
            setNeedsDisplay()
        }
    }
    
    weak var rangeSlider: RangeSlider?
    
    override func draw(in ctx: CGContext) {
        if let slider = rangeSlider {
            let thumbFrame = bounds.insetBy(dx: 2.0, dy: 2.0)
            let cornerRadius = thumbFrame.height * slider.curvaceousness / 2.0
            let thumbPath = UIBezierPath(roundedRect: thumbFrame, cornerRadius: cornerRadius)
            
            // Fill - with a subtle shadow
            let shadowColor = UIColor.gray
            ctx.setShadow(offset: CGSize(width: 0.0, height: 1.0), blur: 1.0, color: shadowColor.cgColor)
            ctx.setFillColor(slider.thumbTintColor.cgColor)
            ctx.addPath(thumbPath.cgPath)
            ctx.fillPath()
            
            // Outline
            ctx.setStrokeColor(shadowColor.cgColor)
            ctx.setLineWidth(0.5)
            ctx.addPath(thumbPath.cgPath)
            ctx.strokePath()
            
            if highlighted {
                ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
                ctx.addPath(thumbPath.cgPath)
                ctx.fillPath()
            }
            
            if let value = thumbValue {
                let textAttributes: [NSAttributedString.Key: AnyObject] = [
                    NSAttributedString.Key.foregroundColor : UIColor.black.cgColor,
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12)
                ]
                let _ = drawText(context: ctx, text: value as NSString, attributes: textAttributes, centeredOn: CGPoint(x: thumbFrame.midX, y: thumbFrame.midY))
            }
        }
    }
    
    private func drawText(context: CGContext, text: NSString, attributes: [NSAttributedString.Key : AnyObject], centeredOn : CGPoint) -> CGSize {
//        let font = attributes[NSAttributedString.Key.font] as! UIFont
        let attributedString = NSAttributedString(string: text as String, attributes: attributes)
        
        let textSize = text.size(withAttributes: attributes)
        
        // y: Add font.descender (its a negative value) to align the text at the baseline
        let textPath    = CGPath(rect: CGRect(x: centeredOn.x - textSize.width / 2, y: centeredOn.y - textSize.height / 2, width: ceil(textSize.width), height: ceil(textSize.height)), transform: nil)
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        let frame       = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: attributedString.length), textPath, nil)
        
        // Flip the coordinate system
        context.textMatrix = CGAffineTransform.identity;
        context.translateBy(x: 0, y: self.bounds.size.height);
        context.scaleBy(x: 1.0, y: -1.0);
        
        CTFrameDraw(frame, context)
        
        return textSize
    }
}
