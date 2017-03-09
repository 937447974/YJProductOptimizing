//
//  ViewController.swift
//  YJProductCleanCycleImport
//
//  Created by 阳君 on 2017/3/9.
//  Copyright © 2017年 YJCocoa. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    private let pClean = YJProductClean()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pClean.projectPath = "/Users/admin/Desktop/GitHub/YJProductClean/YJProductCleanCycleImport"
        self.pClean.ignorePath = ["Podfile", "Podfile.lock", "Pods", "Resources"]
        self.pClean.startClean()
    }

}

