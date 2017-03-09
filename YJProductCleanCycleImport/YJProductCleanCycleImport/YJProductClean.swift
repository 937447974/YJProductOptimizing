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
    /// 所有class文件
    fileprivate var allCycleClasses = Array<String>()
}

// MARK: - public methods
extension YJProductClean {
    
    func startClean() {
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            self.searchAllClasses(relativePath: "")
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
    
    private func searchClass(filePath: String) {
        print("搜索文件：\(filePath)")
        let pathExtension = filePath.nsString.pathExtension
        // add to allClasses
        if pathExtension == "h" {
            let fileName = filePath.nsString.lastPathComponent.nsString.deletingPathExtension
            let productClass = YJProductClass()
            self.allClasses[fileName] = productClass
            productClass.name = fileName
            productClass.hPath = filePath
        }
    }
    
    
    func parsingAllClasses() {
        print("\n\n\n")
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: DispatchQoS.`default`.qosClass)
        for value in self.allClasses.values {
            queue.async(group: group) {
                print("解析文件：\(value.name)\t......")
                self.parsingOCClass(projectClass: value)
            }
        }
        group.notify(queue: queue) {
            self.parsingAllCycleImports()
        }
    }
    
    private func parsingOCClass(projectClass: YJProductClass) {
        do {
            let regex = try NSRegularExpression(pattern: "\"[^\"]+.h\"", options: NSRegularExpression.Options(rawValue: 0))
            let contentFile = try String(contentsOfFile: projectClass.hPath!)
            let matches = regex.matches(in: contentFile, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, contentFile.nsString.length))
            for match in matches {
                var range = match.range
                range.location += 1
                range.length -= 4
                let fileName = contentFile.nsString.substring(with: range)
                if fileName == projectClass.name {
                    continue
                }
                projectClass.imports.append(fileName)
            }
        } catch {
            print(error)
        }
    }
    
    func parsingAllCycleImports() {
        print("\n\n\n")
        for value in self.allClasses.values {
            print("解析循环import文件：\(value.name)\t......")
            self.parsingCycleImport(projectClass: value, path: "")
        }
        print("\n\n\n分析完毕：\(self.allClasses.count)")
        print("\n循环import路径：\(self.allCycleClasses.count)\n\(self.allCycleClasses)")
    }
    
    func parsingCycleImport(projectClass: YJProductClass, path:String) {
        if path.range(of: "-\(projectClass.name)-") != nil {
            self.allCycleClasses.append("\(path)-\(projectClass.name)")
            return
        }
        if projectClass.parsing {
            return
        }
        for className in projectClass.imports {
            if let itemClass = self.allClasses[className] {
                parsingCycleImport(projectClass: itemClass, path:"\(path)-\(projectClass.name)")
            }
        }
        projectClass.parsing = true
    }
    
}

private extension String {
    
    var nsString: NSString {
        get {
            return self as NSString
        }
    }
    
}

