//
//  YJProductClean.swift
//  YJProductClean
//
//  Created by 阳君 on 2017/2/17.
//  Copyright © 2017年 YJCocoa. All rights reserved.
//

import Cocoa

/// 项目分析器,主要分析未使用的class文件
class YJProductClean: NSObject {
    
    // MARK: public attributes
    /** 项目路径*/
    var projectPath: String!
    /** 忽略的路径,相对地址。其完整路径地址为projectPath+ignorePath*/
    var ignorePath: Set<String> = Set()
    
    // MARK:  private attributes
    /// 所有class文件
    fileprivate var allClasses = Dictionary<String, YJProductClass>()
    /// 其他文件
    fileprivate var otherFiles = Array<String>()
    /// 未使用的class文件
    fileprivate var unUsedClasses = Dictionary<String, YJProductClass>()
}

// MARK: - public methods
extension YJProductClean {
    
    func startClean() {
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            self.searchAllClasses(relativePath: "")
            print("\n\n\n")
            self.parsingAllClasses()
        }
    }
}

// MARK: - public methods
private extension YJProductClean {
    
    func searchAllClasses(relativePath: String) {
        if relativePath.hasSuffix(".DS_Store") || relativePath.hasSuffix(".xcodeproj") || relativePath.hasSuffix(".xcworkspace") || relativePath.hasSuffix(".xcassets") || self.ignorePath.contains(relativePath)  {
            return
        }
        let path = self.projectPath.nsString.appendingPathComponent(relativePath)
        if relativePath.hasSuffix(".framework") || relativePath.hasSuffix(".a") || relativePath.hasSuffix(".bundle") {
            self.otherFiles.append(path)
            return
        }
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)
        if (fileManager.fileExists(atPath: path, isDirectory: &isDirectory)) {
            if isDirectory.boolValue {
                do {
                    let childrenPaths = try fileManager.contentsOfDirectory(atPath: path)
                    for childPath in childrenPaths {
                        self.searchAllClasses(relativePath: relativePath.nsString.appendingPathComponent(childPath))
                    }
                } catch  {
                    print(error)
                }
            } else {
                self.searchClass(filePath: path)
            }
        }
    }
    
    func searchClass(filePath: String) {
        print("搜索文件：\(filePath)")
        let pathExtension = filePath.nsString.pathExtension
        // add to allClasses
        let fileName = filePath.nsString.lastPathComponent.nsString.deletingPathExtension
        var productClass = self.allClasses[fileName]
        if productClass == nil {
            productClass = YJProductClass()
            self.allClasses[fileName] = productClass
            productClass!.name = fileName
        }
        if pathExtension == "h" {
            productClass!.hPath = filePath
        } else if pathExtension == "m" {
            productClass!.mPath = filePath
        } else if pathExtension == "xib" {
            productClass!.xibPath = filePath
        } else if pathExtension == "swift" {
            productClass!.swiftPath = filePath
        } else {
            self.allClasses.removeValue(forKey: fileName)
            // add to otherFiles
            self.otherFiles.append(filePath)
        }
    }
    
    func parsingAllClasses() {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: DispatchQoS.`default`.qosClass)
        for value in self.allClasses.values {
            queue.async(group: group) {
                print("解析文件：\(value.name)\t......")
                if value.swiftPath != nil {
                    self.parsingSwiftClass(projectClass: value)
                } else {
                    self.parsingOCClass(projectClass: value)
                }
            }
        }
        group.notify(queue: queue) {
            self.unUsedClasses.removeAll()
            for value in self.allClasses.values {
                if !value.used {
                    self.unUsedClasses[value.name] = value
                }
            }
            print("\n\n\n分析完毕：\(self.allClasses.count)")
            print("\n未使用的文件：\(self.unUsedClasses.count)\n\(self.unUsedClasses)")
            print("\n其他文件:\(self.otherFiles.count)\n\(self.otherFiles)")
        }
    }
    
    func parsingOCClass(projectClass: YJProductClass) {
        var paths = Array<String>()
        if projectClass.hPath != nil {
            paths.append(projectClass.hPath!)
        }
        if projectClass.mPath != nil {
            paths.append(projectClass.mPath!)
        }
        if projectClass.mmPath != nil {
            paths.append(projectClass.mmPath!)
        }
        do {
            let regex = try NSRegularExpression(pattern: "\"[^\"]+.h\"", options: NSRegularExpression.Options(rawValue: 0))
            for path in paths {
                let contentFile = try String(contentsOfFile: path)
                let matches = regex.matches(in: contentFile, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, contentFile.nsString.length))
                for match in matches {
                    var range = match.range
                    range.location += 1
                    range.length -= 4
                    let fileName = contentFile.nsString.substring(with: range)
                    if fileName == projectClass.name {
                        continue
                    }
                    if let usedProjectClass = self.allClasses[fileName] {
                        usedProjectClass.used = true
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func parsingSwiftClass(projectClass: YJProductClass) {
        do {
            let contentFile = try String(contentsOfFile: projectClass.swiftPath!)
            for value in self.allClasses.values {
                if !value.used && value.name != projectClass.name {
                    if contentFile.range(of: value.name) != nil {
                        value.used = true
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
}

private extension String {
    
    var nsString: NSString {
        get {
            return self as NSString
        }
    }
    
}

