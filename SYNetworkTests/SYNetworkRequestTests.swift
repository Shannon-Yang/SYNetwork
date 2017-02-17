//
//  SYNetworkRequestTests.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2016/12/29.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import XCTest
@testable import SYNetwork

class SYNetworkRequestTests: SYNetworkTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasicSuccessHTTPRequest() {
        
        SYNetworkConfig.sharedInstance.baseUrlString = "https://httpbin.org/"
        let get = SYBasicDataRequest(requestUrlString: "get", method: .get, parameters: ["foo": "bar"])
        self.expectSuccess(with: .default, request: get)
        self.expectSuccess(with: .data, request: get)
        self.expectSuccess(with: .string, request: get)
        self.expectSuccess(with: .json(.get), request: get)
        self.expectSuccess(with: .swiftyJSON, request: get)
        
        // test ObjectMapper.
        
        SYNetworkConfig.sharedInstance.baseUrlString = "https://raw.githubusercontent.com/tristanhimmelman/AlamofireObjectMapper/"
        let get_d8b = SYBasicDataRequest(requestUrlString: "d8bb95982be8a11a2308e779bb9a9707ebe42ede/sample_json", method: .get)
        self.expectSuccess(with: .objectMapper(.default), request: get_d8b)
        self.expectSuccess(with: .objectMapper(.object), request: get_d8b)
        
        let get_2ee = SYBasicDataRequest(requestUrlString: "2ee8f34d21e8febfdefb2b3a403f18a43818d70a/sample_keypath_json", method: .get, keyPath: "data")
        self.expectSuccess(with: .objectMapper(.objectKeyPath), request: get_2ee)
        
        let get_927 = SYBasicDataRequest(requestUrlString: "97231a04e6e4970612efcc0b7e0c125a83e3de6e/sample_keypath_json", method: .get, keyPath: "response.data")
        self.expectSuccess(with: .objectMapper(.objectNestedKeyPath), request: get_927)
        
        let get_f58 = SYBasicDataRequest(requestUrlString: "f583be1121dbc5e9b0381b3017718a70c31054f7/sample_array_json", method: .get)
        self.expectSuccess(with: .objectMapper(.array), request: get_f58)
        
        let get_d8bb = SYBasicDataRequest(requestUrlString: "d8bb95982be8a11a2308e779bb9a9707ebe42ede/sample_json", method: .get, keyPath: "three_day_forecast")
        self.expectSuccess(with: .objectMapper(.arrayKeyPath), request: get_d8bb)
        
        let get_9723 = SYBasicDataRequest(requestUrlString: "97231a04e6e4970612efcc0b7e0c125a83e3de6e/sample_keypath_json", method: .get, keyPath: "response.data.three_day_forecast")
        self.expectSuccess(with: .objectMapper(.arrayKeyPath), request: get_9723)
    }
    
    func testResponseHeaders() {
        let request = SYBasicDataRequest(requestUrlString: "response-headers?key=value")
        request.response { defalutDataResponse in
            XCTAssertNotNil(request.headers)
        }
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
