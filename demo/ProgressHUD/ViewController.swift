//
//  ViewController.swift
//  ProgressHUD
//
//  Created by zero on 17/1/18.
//  Copyright © 2017年 zero. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBAction func click(_ sender: Any) {
        //ProgressHUD.showSuccess("测试成功", to: self.view)
        let _ = ProgressHUD.loading(with:"加载中", to: self.view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
    }
    

}

