//
//  YJProductClass.swift
//  YJProductClean
//
//  Created by 阳君 on 2017/2/19.
//  Copyright © 2017年 YJCocoa. All rights reserved.
//

import Cocoa

class YJProductClass: NSObject {
    
    var used = false
    var name: String = ""
    var hPath: String?
    var mPath: String?
    var mmPath: String?
    var xibPath: String?
    var swiftPath: String?
    
    override var description: String {
        var dict = Dictionary<String, String>()
        if self.hPath != nil {
            dict["hPath"] = self.hPath
        }
        if self.mPath != nil {
            dict["mPath"] = self.mPath
        }
        if self.mmPath != nil {
            dict["mmPath"] = self.mmPath
        }
        if self.xibPath != nil {
            dict["xibPath"] = self.xibPath
        }
        if self.swiftPath != nil {
            dict["swiftPath"] = self.swiftPath
        }
        return "\(dict)"
    }
}
