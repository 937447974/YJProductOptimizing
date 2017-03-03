//
//  ViewController.swift
//  YJProductCleanImport
//
//  Created by 阳君 on 2017/3/3.
//  Copyright © 2017年 YJCocoa. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    private let pClean = YJProductClean()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pClean.projectPath = "/Users/admin/Desktop/mobile_ios/JuMei/Src/Tag/1.0.0/Classes/Controller/Search"
        self.pClean.ignorePath = ["Podfile", "Podfile.lock", "Pods", "Resources"]
        self.pClean.startClean()
    }
    
}

