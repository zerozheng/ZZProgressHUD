//
//  RoundProgressView.swift
//  MBProgressHUD
//
//  Created by zero on 17/1/16.
//  Copyright © 2017年 zero. All rights reserved.
//

import UIKit

internal class RoundProgressView: UIView {

    var progress: CGFloat {
        didSet {
            if oldValue != progress {
                self.setNeedsDisplay()
            }
        }
    }
    
    var progressTintColor: UIColor{
        didSet {
            if oldValue != progressTintColor && !oldValue.isEqual(progressTintColor) {
                self.setNeedsDisplay()
            }
        }
    }
    
    var backgroundTintColor: UIColor{
        didSet {
            if oldValue != backgroundTintColor && !oldValue.isEqual(backgroundTintColor) {
                self.setNeedsDisplay()
            }
        }
    }
    
    ///Display mode, NO = round or YES = annular. Defaults to round.
    var annular: Bool
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
    }
    
    override init(frame: CGRect) {
        self.progress = 0
        self.annular = false
        self.progressTintColor = UIColor(white: 1, alpha: 1)
        self.backgroundTintColor = UIColor(white: 1, alpha: 1)
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        if self.annular {
            let lineWidth: CGFloat = 2
            let processBackgroundPath: UIBezierPath = UIBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .butt
            let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
            let radius = (self.bounds.width - lineWidth)/2
            let startAngle = CGFloat(-Double.pi/2)
            var endAngle = 2*CGFloat(Double.pi) + startAngle
            processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            self.backgroundColor?.set()
            processBackgroundPath.stroke()
            
            let processPath = UIBezierPath()
            processPath.lineCapStyle = .square
            processPath.lineWidth = lineWidth
            endAngle = self.progress * 2 * CGFloat(Double.pi) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            self.progressTintColor.set()
            processPath.stroke()
        }else{
            let lineWidth:CGFloat = 2
            let allRect = self.bounds
            let circleRect = allRect.insetBy(dx: lineWidth/2, dy: lineWidth/2)
            let center = CGPoint(x: allRect.midX, y: allRect.midY)
            self.progressTintColor.setStroke()
            self.backgroundTintColor.setFill()
            context.setLineWidth(lineWidth)
            context.strokeEllipse(in: circleRect)
            
            let startAngle = CGFloat(-Double.pi/2)
            let processPath = UIBezierPath()
            processPath.lineCapStyle = .butt
            processPath.lineWidth = lineWidth*2
            let radius = allRect.width/2 - processPath.lineWidth/2
            let endAngle = self.progress * 2 * CGFloat(Double.pi) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.setBlendMode(.copy)
            self.progressTintColor.set()
            processPath.stroke()
        }
    }
}
