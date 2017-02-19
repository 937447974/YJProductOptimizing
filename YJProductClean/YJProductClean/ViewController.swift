//
//  ViewController.swift
//  YJProductClean
//
//  Created by 阳君 on 2017/2/17.
//  Copyright © 2017年 YJCocoa. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    private let pClean = YJProductClean()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pClean.projectPath = "/Users/admin/Desktop/YJProductClean"//"/Users/admin/Desktop/GitHub/YJCocoa/Developer/DeveloperTools/YJTimeProfiler"
        self.pClean.ignorePath = ["Podfile", "Podfile.lock", "Pods"]
        self.pClean.startClean()
    }

    // MARK: - YJProductCleanDelegate
    func productCleanError(error: NSError) {
        
    }

}
