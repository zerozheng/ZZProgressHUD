//
//  RoundedButton.swift
//  MBProgressHUD
//
//  Created by zero on 17/1/16.
//  Copyright © 2017年 zero. All rights reserved.
//

import UIKit

internal class RoundedButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = ceil(self.bounds.height/2)
    }
    
    override var intrinsicContentSize: CGSize {
        if case UIControlEvents(rawValue: 0) = self.allControlEvents {
            return CGSize.zero
        }else{
            var size = super.intrinsicContentSize
            size.width += 20
            return size
        }
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        super.setTitleColor(color, for: state)
        updateBackgroundColor()
        self.layer.borderColor = color?.cgColor
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }
    
    private func updateBackgroundColor() {
        let baseColor = self.titleColor(for: .selected)
        self.backgroundColor = isHighlighted ? baseColor?.withAlphaComponent(0.1) : UIColor.clear
    }
}
