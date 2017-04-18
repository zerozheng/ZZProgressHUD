//
//  BarProgressView.swift
//  MBProgressHUD
//
//  Created by zero on 17/1/16.
//  Copyright © 2017年 zero. All rights reserved.
//

import UIKit

internal class BarProgressView: UIView {
    
    var progress: CGFloat {
        didSet {
            if progress != oldValue {
                self.setNeedsDisplay()
            }
        }
    }
    var lineColor: UIColor
    var progressColor: UIColor {
        didSet {
            if oldValue != progressColor && !oldValue.isEqual(progressColor) {
                self.setNeedsDisplay()
            }
        }
    }
    
    ///Bar background color.
    var progressRemainingColor: UIColor {
        didSet {
            if oldValue != progressRemainingColor && !oldValue.isEqual(progressRemainingColor) {
                self.setNeedsDisplay()
            }
        }
    }
    
    convenience init () {
        self.init(frame:CGRect(x: 0, y: 0, width: 120, height: 20))
    }
    
    override init(frame: CGRect) {
        self.progress = 0
        self.lineColor = UIColor.white
        self.progressColor = UIColor.white
        self.progressRemainingColor = UIColor.clear
        super.init(frame: frame)
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 120, height: 10)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineWidth(2)
        context.setStrokeColor(self.lineColor.cgColor)
        context.setFillColor(self.progressRemainingColor.cgColor)
        
        // Draw background
        var radius = (rect.height / 2) - 2
        context.move(to: CGPoint(x: 2, y: rect.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius+2, y: 2), radius: radius)
        context.addLine(to: CGPoint(x: rect.width-radius-2, y: 2))
        context.addArc(tangent1End: CGPoint(x:rect.width - 2, y:2), tangent2End: CGPoint(x:rect.width - 2, y:rect.height / 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2, y: rect.height - 2), tangent2End: CGPoint(x: rect.width - radius - 2, y: rect.height - 2), radius: radius)
        context.addLine(to: CGPoint(x: radius + 2, y: rect.height - 2))
        context.addArc(tangent1End: CGPoint(x:2, y: rect.height - 2), tangent2End: CGPoint(x:2, y: rect.height/2), radius: radius)
        context.fillPath()
        
        // Draw border
        context.move(to: CGPoint(x: 2, y: rect.height/2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius+2, y: 2), radius: radius)
        context.addLine(to: CGPoint(x: rect.width - radius - 2, y: 2))
        context.addArc(tangent1End: CGPoint(x:rect.width - 2, y:2), tangent2End: CGPoint(x:rect.width - 2,y:rect.height / 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x:rect.width - 2, y:rect.height - 2), tangent2End: CGPoint(x:rect.width - radius - 2, y:rect.height - 2), radius: radius)
        context.addLine(to: CGPoint(x: radius + 2, y: rect.height - 2))
        context.addArc(tangent1End: CGPoint(x:2, y:rect.height - 2), tangent2End: CGPoint(x:2, y:rect.height/2), radius: radius)
        context.strokePath()
        
        context.setFillColor(self.progressColor.cgColor)
        radius = radius - 2
        let amount = self.progress * rect.width
        
        // Progress in the middle area
        if amount >= radius + 4 && amount <= rect.width - radius - 4 {
            context.move(to: CGPoint(x: 4, y: rect.height/2))
            context.addArc(tangent1End: CGPoint(x:4,y:4), tangent2End: CGPoint(x:radius+4,y:4), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: 4))
            context.addLine(to: CGPoint(x: amount, y: radius+4))
            
            context.move(to: CGPoint(x: 4, y: rect.height/2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.height - 4), tangent2End: CGPoint(x: radius + 4, y: rect.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: rect.height-4))
            context.addLine(to: CGPoint(x: amount, y: radius + 4))
            context.fillPath()
        }else if amount > radius + 4 {// Progress in the right arc
            let x = amount - rect.width + radius + 4
            context.move(to: CGPoint(x: 4, y: rect.height/2))
            context.addArc(tangent1End: CGPoint(x:4, y:4), tangent2End: CGPoint(x:radius + 4, y:4), radius: radius)
            context.addLine(to: CGPoint(x: rect.width - radius - 4, y: 4))
            
            var angle = -acos(x/radius)
            context.addArc(center: CGPoint(x:rect.width - radius - 4, y:rect.height/2), radius: radius, startAngle: CGFloat(Double.pi), endAngle: angle, clockwise: false)
            context.addLine(to: CGPoint(x: amount, y: rect.height/2))
            context.move(to: CGPoint(x: 4, y: rect.height/2))
            context.addArc(tangent1End: CGPoint(x:4, y:rect.height-4), tangent2End: CGPoint(x: radius+4, y: rect.height-4), radius: radius)
            context.addLine(to: CGPoint(x: rect.width - radius - 4, y: rect.height - 4))
            angle = acos(x/radius)
            
            context.addArc(center: CGPoint(x:rect.width - radius - 4, y:rect.height/2), radius: radius, startAngle: CGFloat(-Double.pi), endAngle: angle, clockwise: true)
            context.addLine(to: CGPoint(x: amount, y: rect.height/2))
            context.fillPath()
        } else if amount < radius + 4 && amount > 0 {// Progress is in the left arc
            context.move(to: CGPoint(x: 4, y: rect.height/2))
            context.addArc(tangent1End: CGPoint(x:4,y:4), tangent2End: CGPoint(x:radius + 4,y:4), radius: radius)
            context.addLine(to: CGPoint(x: radius + 4, y: rect.height/2))
            context.move(to: CGPoint(x: 4, y: rect.height/2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.height-4), tangent2End: CGPoint(x: radius + 4, y: rect.height - 4), radius: radius)
            context.addLine(to: CGPoint(x: radius+4, y: rect.height/2))
            context.fillPath()
        }
    }
}
