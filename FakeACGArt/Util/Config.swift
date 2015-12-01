//
//  Config.swift
//  BellOA2
//
//  Created by mini4 on 15/11/3.
//  Copyright © 2015年 makcoo. All rights reserved.
//

import Foundation
import XCGLogger

// 初始化log
let log: XCGLogger = {
    let log = XCGLogger.defaultInstance()
    #if DEBUG
        log.setup(.Verbose, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, fileLogLevel: .Verbose)
    #else
        log.setup(.None, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, fileLogLevel: .None)
    #endif
    return log
}()

let ColorMain: UIColor = UIColor(red: 61 / 255.0, green: 204 / 255.0, blue: 173 / 255.0, alpha: 1)

let ColorMainLight: UIColor = UIColor(red: 135 / 255.0, green: 206 / 255.0, blue: 250 / 255.0, alpha: 1)

let ColorAntiMain: UIColor = UIColor(red: 245 / 255.0, green: 183 / 255.0, blue: 35 / 255.0, alpha: 1)

enum ImageSizeEnum: String {
    case small = "_uploadfiles/iphone5/200/"
    case middle = "_uploadfiles/iphone5/400/"
    case big = "_uploadfiles/iphone5/640/"
}

func imageUrl(urlStr: String, size:ImageSizeEnum) -> NSURL? {
    return NSURL(string: ApiClient.sharedApiClient.RootApi + size.rawValue + urlStr)
}

enum SuggestType: String {
    case hot = "today_download"
    case top = "history_top"
}

