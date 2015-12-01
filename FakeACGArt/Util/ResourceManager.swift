//
//  ResourceManager.swift
//  FakeACGArt
//
//  Created by john on 15/12/2.
//  Copyright © 2015年 john. All rights reserved.
//

import Foundation

private let FileName = "json_daily.php"

private var FilePath: String {
    let separator = NSString(string: FileName).rangeOfString(".")
    let fileNamePrefix = NSString(string: FileName).substringToIndex(separator.location)
    let fileNamePostfix = NSString(string: FileName).substringFromIndex(separator.location + separator.length)
    return NSBundle.mainBundle().pathForResource(fileNamePrefix, ofType: fileNamePostfix)!
}

class ResourceManager {
    
    /// 单例
    static let sharedResourceManager: ResourceManager = {
        let sharedInstance = ResourceManager()
        
        return sharedInstance
    }()
    
    var GlobalConfig: [String: AnyObject]?
    
    private init() {
        self.loadLastConfigFromFile()
    }

    private func loadLastConfigFromFile() {
        GlobalConfig = NSDictionary(contentsOfFile: FilePath) as? [String: AnyObject]
    }
    
    class func UpdateResource(r: [String: AnyObject]) {
        sharedResourceManager.GlobalConfig = r
        // 写入文件
        if NSDictionary(dictionary: ["A": 1]).writeToFile(FilePath, atomically: true) == false {
            log.error("write file failed")
        }
    }
    
}
