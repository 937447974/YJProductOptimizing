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
    /// 未使用的import
    fileprivate var unUsedImports = Dictionary<String, Array<String>>()
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
        if relativePath.hasSuffix(".DS_Store") ||
            relativePath.hasSuffix(".xcodeproj") ||
            relativePath.hasSuffix(".xcworkspace") ||
            relativePath.hasSuffix(".xcassets") ||
            relativePath.hasSuffix(".framework") ||
            relativePath.hasSuffix(".a") ||
            relativePath.hasSuffix(".bundle") ||
            self.ignorePath.contains(relativePath) {
            return
        }
        let path = self.projectPath.nsString.appendingPathComponent(relativePath)
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
        } else if pathExtension != "xib" {
            self.allClasses.removeValue(forKey: fileName)
        }
    }
    
    func parsingAllClasses() {
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: DispatchQoS.`default`.qosClass)
        for value in self.allClasses.values {
            queue.async(group: group) {
                print("解析文件：\(value.name)\t......")
                self.parsingOCClass(projectClass: value)
            }
        }
        group.notify(queue: queue) {
            for value in self.allClasses.values {
                if value.unUsedImports.count != 0 {
                    self.unUsedImports[value.name] = value.unUsedImports
                }
            }
            print("\n\n\n分析完毕：\(self.allClasses.count)")
            print("\n未使用的import导入：\(self.unUsedImports.count)\n\(self.unUsedImports)")
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
                    if !self.checkUsed(contentFile: contentFile, importName: fileName) {
                        projectClass.unUsedImports.append(fileName)
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    func checkUsed(contentFile:String, importName:String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: importName, options: NSRegularExpression.Options(rawValue: 0))
            let matches = regex.matches(in: contentFile, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, contentFile.nsString.length))
            return matches.count > 1
        } catch {
            print(error)
        }
        return false
    }
    
}

private extension String {
    
    var nsString: NSString {
        get {
            return self as NSString
        }
    }
    
}

