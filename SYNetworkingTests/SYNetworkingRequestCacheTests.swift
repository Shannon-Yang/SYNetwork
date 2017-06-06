//
//  SYNetworkingRequestCacheTests.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/4.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import XCTest
@testable import SYNetworking

class SYNetworkingRequestCacheTests: SYNetworkTestCase {
    
    var get: SYBasicDataRequest?
    
    override func setUp() {
        super.setUp()
        SYNetworkingConfig.sharedInstance.baseURLString = "https://httpbin.org/"
        get = SYBasicDataRequest(requestUrlString: "get", method: .get, parameters: ["foo": "bar"])
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testBasicResponseDataSourceServer() {
        self.expectSuccess(.server, request: get)
    }
    
    func testBasicResponseDataSourceCacheIfPossible() {
        self.expectSuccess(.cacheIfPossible, request: get)
    }
    
    func testBasicResponseDataSourceCacheAndServer() {
        self.expectSuccess(.cacheAndServer, request: get)
    }

    func testCacheKey() {
        
        let key1 = "version 1"
        let key2 = "version 2"
        
        let get1 = SYBasicDataRequest(requestUrlString: "get", method: .get, parameters: ["foo": "bar"], cacheKey: key1)
        
        let exp1 = self.expectation(description: "Request should succeed")
        get1.responseJSON(responseDataSource: .cacheIfPossible, { (isDataFromCache, dataResponse) in
            // First time. Data should not be from cache.
            XCTAssertFalse(isDataFromCache)
            exp1.fulfill()
        })
        self.waitForExpectationsWithCommonTimeout()
        
        sleep(6)
        
        // Request again.
        let exp2 = self.expectation(description: "Request should succeed")
        get1.responseJSON(responseDataSource: .cacheIfPossible) { (isDataFromCache, dataResponse) in
            // This time data should be from cache.
            XCTAssertTrue(isDataFromCache)
            exp2.fulfill()
        }
        self.waitForExpectationsWithCommonTimeout()
        
        
        let get2 = SYBasicDataRequest(requestUrlString: "get", method: .get, parameters: ["foo": "bar"], cacheKey: key2)
        
        let exp3 = self.expectation(description: "Request should succeed")
        get2.responseJSON(responseDataSource: .cacheIfPossible, { (isDataFromCache, dataResponse) in
            // Data should not be from cache because cacheKey has changed.
            XCTAssertFalse(isDataFromCache)
            exp3.fulfill()
        })
        self.waitForExpectationsWithCommonTimeout()
        
        sleep(6)
        
        // request again
        
        let exp4 = self.expectation(description: "Request should succeed")
        get2.responseJSON(responseDataSource: .cacheIfPossible) { (isDataFromCache, dataResponse) in
            // This time data should be from cache.
            XCTAssertTrue(isDataFromCache)
            exp4.fulfill()
        }
        self.waitForExpectationsWithCommonTimeout()
    }
}




