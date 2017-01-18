//
//  BackgroundView.swift
//  MBProgressHUD
//
//  Created by zero on 17/1/16.
//  Copyright © 2017年 zero. All rights reserved.
//

import UIKit

internal class BackgroundView: UIView {

    /// Defaults to MBProgressHUDBackgroundStyleBlur
    var style: BackgroundStyle {
        get { return self.innerStyle }
        
        set {
            if style != newValue {
                innerStyle = newValue
                self.updateForBackgroundStyle()
            }
        }
    }
    
    /// The background color or the blur tint color.
    var color: UIColor {
        get { return self.innerColor }
        
        set {
            if color != newValue {
                innerColor = newValue
                self.updateViews(forColor: newValue)
            }
        }
    }
    
    private var innerStyle: BackgroundStyle
    
    private var innerColor: UIColor
    
    private var effectView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        self.innerStyle = .blur
        self.innerColor = UIColor(white: 0.8, alpha: 0.6)
        super.init(frame: frame)
        self.clipsToBounds = true
        self.updateForBackgroundStyle()
     }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
    override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }
    
    func updateForBackgroundStyle() {
        if case .blur = self.style {
            self.effectView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .light))
            self.addSubview(self.effectView!)
            self.effectView!.frame = self.bounds
            self.effectView!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            self.backgroundColor = self.color
            self.layer.allowsGroupOpacity = false
        }else{
            self.effectView?.removeFromSuperview()
            self.effectView = nil
            self.backgroundColor = self.color
        }
        
    }
    

    func updateViews(forColor: UIColor) {
        self.backgroundColor = self.color
    }
}
