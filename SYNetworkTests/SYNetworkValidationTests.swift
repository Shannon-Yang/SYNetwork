//
//  SYNetworkValidationTests.swift
//  SYNetworkExample
//
//  Created by Shannon Yang on 2017/2/4.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import SwiftyJSON
import XCTest
@testable import SYNetwork

class SYNetworkValidationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        SYNetworkConfig.sharedInstance.baseUrlString = "https://httpbin.org/"
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testThatValidationForRequestWithAcceptableStatusCodeResponseSucceeds() {
        
        let expectation1 = self.expectation(description: "request should return 200 status code")
        let expectation2 = self.expectation(description: "download should return 200 status code")
        
        var requestError: Error?
        var downloadError: Error?
        
        let request = SYNetworkValidationRequest(requestUrlString: "status/200")
        request.validate(statusCode: 200..<300).response { resp in
            requestError = resp.error
            expectation1.fulfill()
        }
        
        let downloadRequest = SYNetworkValidationDownloadRequest(requestUrlString: "status/200")
        downloadRequest.validate(statusCode: 200..<300).response { resp in
            downloadError = resp.error
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }
    
    
    func testThatValidationForRequestWithUnacceptableStatusCodeResponseFails() {
        // Given
        let urlString = "https://httpbin.org/status/404"
        
        let expectation1 = self.expectation(description: "request should return 404 status code")
        let expectation2 = self.expectation(description: "download should return 404 status code")
        
        var requestError: Error?
        var downloadError: Error?
        
        // When
        let request = SYNetworkValidationRequest(requestUrlString: urlString)
        request
            .validate(statusCode: [200])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
        }
        
        let download = SYNetworkDownloadRequest(requestUrlString: urlString)
        
        download
            .validate(statusCode: [200])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
        
        for error in [requestError, downloadError] {
            if let error = error as? AFError, let statusCode = error.responseCode {
                XCTAssertTrue(error.isUnacceptableStatusCode)
                XCTAssertEqual(statusCode, 404)
            } else {
                XCTFail("Error should not be nil, should be an AFError, and should have an associated statusCode.")
            }
        }
    }
    
}


// MARK: -

class ContentTypeValidationTestCase: XCTestCase {
    func testThatValidationForRequestWithAcceptableContentTypeResponseSucceeds() {
        // Given
        let urlString = "https://httpbin.org/ip"
        
        let expectation1 = self.expectation(description: "request should succeed and return ip")
        let expectation2 = self.expectation(description: "download should succeed and return ip")
        
        var requestError: Error?
        var downloadError: Error?
        
        // When
        let request = SYNetworkValidationRequest(requestUrlString: urlString)
        request
            .validate(contentType: ["application/json"])
            .validate(contentType: ["application/json;charset=utf8"])
            .validate(contentType: ["application/json;q=0.8;charset=utf8"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
        }
        
        let download = SYNetworkDownloadRequest(requestUrlString: urlString)
        download
            .validate(contentType: ["application/json"])
            .validate(contentType: ["application/json;charset=utf8"])
            .validate(contentType: ["application/json;q=0.8;charset=utf8"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }
    
    func testThatValidationForRequestWithAcceptableWildcardContentTypeResponseSucceeds() {
        // Given
        let urlString = "https://httpbin.org/ip"
        
        let expectation1 = self.expectation(description: "request should succeed and return ip")
        let expectation2 = self.expectation(description: "download should succeed and return ip")
        
        var requestError: Error?
        var downloadError: Error?
        
        // When
        let request = SYNetworkValidationRequest(requestUrlString: urlString)
        request
            .validate(contentType: ["*/*"])
            .validate(contentType: ["application/*"])
            .validate(contentType: ["*/json"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
        }
        let download = SYNetworkDownloadRequest(requestUrlString: urlString)
        download
            .validate(contentType: ["*/*"])
            .validate(contentType: ["application/*"])
            .validate(contentType: ["*/json"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }
    
    func testThatValidationForRequestWithUnacceptableContentTypeResponseFails() {
        // Given
        let urlString = "https://httpbin.org/xml"
        
        let expectation1 = self.expectation(description: "request should succeed and return xml")
        let expectation2 = self.expectation(description: "download should succeed and return xml")
        
        var requestError: Error?
        var downloadError: Error?
        
        // When
        let request = SYNetworkValidationRequest(requestUrlString: urlString)
        request
            .validate(contentType: ["application/octet-stream"])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
        }
        
        let download = SYNetworkDownloadRequest(requestUrlString: urlString)
        download
            .validate(contentType: ["application/octet-stream"])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
        
        for error in [requestError, downloadError] {
            if let error = error as? AFError {
                XCTAssertTrue(error.isUnacceptableContentType)
                XCTAssertEqual(error.responseContentType, "application/xml")
                XCTAssertEqual(error.acceptableContentTypes?.first, "application/octet-stream")
            } else {
                XCTFail("error should not be nil")
            }
        }
    }
    
    func testThatValidationForRequestWithNoAcceptableContentTypeResponseFails() {
        // Given
        let urlString = "https://httpbin.org/xml"
        
        let expectation1 = self.expectation(description: "request should succeed and return xml")
        let expectation2 = self.expectation(description: "download should succeed and return xml")
        
        var requestError: Error?
        var downloadError: Error?
        
        // When
        let request = SYNetworkValidationRequest(requestUrlString: urlString)
        request
            .validate(contentType: [])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
        }
        
        let download = SYNetworkDownloadRequest(requestUrlString: urlString)
        download
            .validate(contentType: [])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNotNil(requestError)
        XCTAssertNotNil(downloadError)
        
        for error in [requestError, downloadError] {
            if let error = error as? AFError {
                XCTAssertTrue(error.isUnacceptableContentType)
                XCTAssertEqual(error.responseContentType, "application/xml")
                XCTAssertTrue(error.acceptableContentTypes?.isEmpty ?? false)
            } else {
                XCTFail("error should not be nil")
            }
        }
    }
    
    func testThatValidationForRequestWithNoAcceptableContentTypeResponseSucceedsWhenNoDataIsReturned() {
        // Given
        let urlString = "https://httpbin.org/status/204"
        
        let expectation1 = self.expectation(description: "request should succeed and return no data")
        let expectation2 = self.expectation(description: "download should succeed and return no data")
        
        var requestError: Error?
        var downloadError: Error?
        
        // When
        let request = SYNetworkValidationRequest(requestUrlString: urlString)
        request
            .validate(contentType: [])
            .response { resp in
                requestError = resp.error
                expectation1.fulfill()
        }
        let download = SYNetworkDownloadRequest(requestUrlString: urlString)
        download
            .validate(contentType: [])
            .response { resp in
                downloadError = resp.error
                expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 30, handler: nil)
        
        // Then
        XCTAssertNil(requestError)
        XCTAssertNil(downloadError)
    }
}



