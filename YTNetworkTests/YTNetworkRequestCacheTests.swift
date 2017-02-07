//
//  YTNetworkRequestCacheTests.swift
//  YTNetworkExample
//
//  Created by Shannon Yang on 2017/2/4.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
@testable import YTNetwork

class YTNetworkRequestCacheTests: YTNetworkTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCacheIsNotSendRequetIfCache() {
        YTNetworkConfig.sharedInstance.baseUrlString = "https://httpbin.org/"
        let get = YTBasicDataRequest(requestUrlString: "get", method: .get, parameters: ["foo": "bar"])
        self.expectSuccessWithNotSendRequetIfCache(request: get)
    }
}












