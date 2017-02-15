//
//  YTNetworkTestCase.swift
//  YTNetworkExample
//
//  Created by Shannon Yang on 2017/1/20.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import UIKit
import XCTest
import Alamofire
@testable import YTNetwork

enum JSONTestType {
    case get
    case post
}

enum ObjectMapperType {
    case `default`
    case object
    case objectKeyPath
    case objectNestedKeyPath
    case array
    case arrayKeyPath
    case arrayNestedKeyPath
}

enum ResponseType {
    case `default`
    case  data
    case  string
    case  json(JSONTestType)
    case  propertyList
    case  swiftyJSON
    case  objectMapper(ObjectMapperType)
}

class YTNetworkTestCase: XCTestCase {
    
    func expectSuccess(with type: ResponseType, request: YTBasicDataRequest, assertion: (() -> Void)? = nil) {
        let exp = self.expectation(description: "Request should succeed")
        switch type {
        case .default:
            request.response({ defalutDataResponse in
                XCTAssertNotNil(request)
                XCTAssertNotNil(defalutDataResponse)
                XCTAssertNotNil(defalutDataResponse.data)
                if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
                    XCTAssertNotNil(defalutDataResponse.metrics)
                }
                exp.fulfill()
            })
        case .data:
            request.responseData({ (isDataFromCache, dataResponse) in
                XCTAssertEqual(dataResponse.result.isSuccess, true)
                XCTAssertNotNil(request)
                XCTAssertNotNil(dataResponse)
                XCTAssertNotNil(dataResponse.data)
                if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
                    XCTAssertNotNil(dataResponse.metrics)
                }
                exp.fulfill()
            })
        case .string:
            request.responseString({ (isDataFromCache, dataResponse) in
                XCTAssertNotNil(dataResponse.request)
                XCTAssertNotNil(dataResponse.response)
                XCTAssertNotNil(dataResponse.data)
                XCTAssertEqual(dataResponse.result.isSuccess, true)
                if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
                    XCTAssertNotNil(dataResponse.metrics)
                }
                exp.fulfill()
            })
        case .json(let type):
            switch type {
            case .get:
                request.responseJSON({ (isDataFromCache, dataResponse) in
                    XCTAssertNotNil(dataResponse.request)
                    XCTAssertNotNil(dataResponse.response)
                    XCTAssertNotNil(dataResponse.data)
                    XCTAssertEqual(dataResponse.result.isSuccess, true)
                    if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
                        XCTAssertNotNil(dataResponse.metrics)
                    }
                    
                    // The `as NSString` cast is necessary due to a compiler bug. See the following rdar for more info.
                    // - https://openradar.appspot.com/radar?id=5517037090635776
                    if let args = (dataResponse.result.value as AnyObject?)?["args" as NSString] as? [String: String] {
                        XCTAssertEqual(args, ["foo": "bar"], "args should match parameters")
                    } else {
                        XCTFail("args should not be nil")
                    }
                    exp.fulfill()
                })
            case .post:
                request.responseJSON({ (isDataFromCache, dataResponse) in
                    // Then
                    XCTAssertNotNil(dataResponse.request)
                    XCTAssertNotNil(dataResponse.response)
                    XCTAssertNotNil(dataResponse.data)
                    XCTAssertNotNil(dataResponse.data)
                    XCTAssertEqual(dataResponse.result.isSuccess, true)
                    
                    if #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) {
                        XCTAssertNotNil(dataResponse.metrics)
                    }
                    
                    // The `as NSString` cast is necessary due to a compiler bug. See the following rdar for more info.
                    // - https://openradar.appspot.com/radar?id=5517037090635776
                    if let form = (dataResponse.result.value as AnyObject?)?["form" as NSString] as? [String: String] {
                        XCTAssertEqual(form, ["foo": "bar"], "form should match parameters")
                    } else {
                        XCTFail("form should not be nil")
                    }
                })
            }
            
        case .swiftyJSON:
            request.responseSwiftyJSON({ (isDataFromCache, dataResponse) in
                XCTAssertNotNil(dataResponse.request)
                XCTAssertNotNil(dataResponse.response)
                XCTAssertNotNil(dataResponse.data)
                XCTAssertNotNil(dataResponse.data)
                XCTAssertEqual(dataResponse.result.isSuccess, true)
                XCTAssertNotNil(dataResponse.value)
                exp.fulfill()
            })
            
        case .objectMapper(let value):
            switch value {
            case .default:
                request.responseObject(completionHandler: { (isDataFromCache, dataResponse: DataResponse<WeatherResponse>) in
                    exp.fulfill()
                    let mappedObject = dataResponse.result.value
                    XCTAssertNotNil(mappedObject, "Response should not be nil")
                    XCTAssertNotNil(mappedObject?.location, "Location should not be nil")
                    XCTAssertNotNil(mappedObject?.threeDayForecast, "ThreeDayForcast should not be nil")
                    
                    for forecast in mappedObject!.threeDayForecast! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            case .object:
                let weatherResponse = WeatherResponse()
                weatherResponse.date = Date()
                request.responseObject(mapToObject: weatherResponse, completionHandler: { (isDataFromCache, dataResponse: DataResponse<WeatherResponse>) in
                    exp.fulfill()
                    let mappedObject = dataResponse.result.value
                    XCTAssertNotNil(mappedObject, "Response should not be nil")
                    XCTAssertNotNil(mappedObject?.date, "Date should not be nil") // Date is not in JSON but should not be nil because we mapped onto an existing object with a date set
                    XCTAssertNotNil(mappedObject?.location, "Location should not be nil")
                    XCTAssertNotNil(mappedObject?.threeDayForecast, "ThreeDayForcast should not be nil")
                    
                    for forecast in mappedObject!.threeDayForecast! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            case .objectKeyPath:
                request.responseObject(completionHandler: { (isDataFromCache, dataResponse: DataResponse<WeatherResponse>) in
                    exp.fulfill()
                    
                    let mappedObject = dataResponse.result.value
                    
                    XCTAssertNotNil(mappedObject, "Response should not be nil")
                    XCTAssertNotNil(mappedObject?.location, "Location should not be nil")
                    XCTAssertNotNil(mappedObject?.threeDayForecast, "ThreeDayForcast should not be nil")
                    
                    for forecast in mappedObject!.threeDayForecast! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            case .objectNestedKeyPath:
                request.responseObject(completionHandler: { (isDataFromCache, dataResponse: DataResponse<WeatherResponse>) in
                    exp.fulfill()
                    let mappedObject = dataResponse.result.value
                    
                    XCTAssertNotNil(mappedObject, "Response should not be nil")
                    XCTAssertNotNil(mappedObject?.location, "Location should not be nil")
                    XCTAssertNotNil(mappedObject?.threeDayForecast, "ThreeDayForcast should not be nil")
                    
                    for forecast in mappedObject!.threeDayForecast! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            case .array:
                request.responseObjectArray(completionHandler: { (isDataFromCache, dataResponse: DataResponse<[Forecast]>) in
                    exp.fulfill()
                    let mappedArray = dataResponse.result.value
                    
                    XCTAssertNotNil(mappedArray, "Response should not be nil")
                    
                    for forecast in mappedArray! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            case .arrayKeyPath:
                request.responseObjectArray(completionHandler: { (isDataFromCache, dataResponse: DataResponse<[Forecast]>) in
                    exp.fulfill()
                    let mappedArray = dataResponse.result.value
                    
                    XCTAssertNotNil(mappedArray, "Response should not be nil")
                    
                    for forecast in mappedArray! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            case .arrayNestedKeyPath:
                request.responseObjectArray(completionHandler: { (isDataFromCache, dataResponse: DataResponse<[Forecast]>) in
                    exp.fulfill()
                    let mappedArray = dataResponse.result.value
                    
                    XCTAssertNotNil(mappedArray, "Response should not be nil")
                    
                    for forecast in mappedArray! {
                        XCTAssertNotNil(forecast.day, "day should not be nil")
                        XCTAssertNotNil(forecast.conditions, "conditions should not be nil")
                        XCTAssertNotNil(forecast.temperature, "temperature should not be nil")
                    }
                })
            }
        default:
            break
        }
        self.waitForExpectationsWithCommonTimeout()
    }
    
    func expectFailure(with type: ResponseType, request: YTBasicDataRequest, assertion: (() -> Void)? = nil) {
        let exp = self.expectation(description: "Request should fail")
        switch type {
        case .default:
            request.response({ (defalutDataResponse) in
                XCTAssertNotNil(defalutDataResponse.request)
                XCTAssertNil(defalutDataResponse.response)
                XCTAssertNotNil(defalutDataResponse.data)
                XCTAssertNotNil(defalutDataResponse.error)
            })
        case .data:
            request.responseData { (isDataFromCache, dataResponse) in
                switch dataResponse.result {
                case .success( _):
                    XCTFail("Request should fail, but succeeded")
                    exp.fulfill()
                case .failure(let error):
                    XCTAssertNotNil(error)
                    XCTAssertNotNil(request)
                    exp.fulfill()
                }
            }
        default:
            break
        }
        self.waitForExpectationsWithCommonTimeout()
    }
    
    func expectSuccess(_ responseDataSource: ResponseDataSource, request: YTBasicDataRequest?) {
        guard let request = request else {
            return
        }
        let exp = self.expectation(description: "Request should succeed")
        
        switch responseDataSource {
        case .server:
            request.responseJSON(responseDataSource: responseDataSource) { (isDataFromCache, dataResponse) in
                // Data should not be from cache.
                XCTAssertFalse(isDataFromCache)
                XCTAssertNotNil(dataResponse)
                XCTAssertNotNil(dataResponse.result)
                XCTAssertNotNil(dataResponse.data)
                exp.fulfill()
            }
        case .cacheIfPossible:
            request.responseJSON(responseDataSource: responseDataSource) { (isDataFromCache, dataResponse) in
                // First time. Data should not be from cache. should from server
                XCTAssertFalse(isDataFromCache)
                XCTAssertNotNil(dataResponse)
                XCTAssertNotNil(dataResponse.result)
                XCTAssertNotNil(dataResponse.data)
                exp.fulfill()
            }
            
            self.waitForExpectationsWithCommonTimeout()
            
            sleep(5)
            
            // Request again.
             let exp = self.expectation(description: "Request should fail")
            request.responseJSON(responseDataSource: responseDataSource) { (isDataFromCache, dataResponse) in
                // This time data should be from cache.
                XCTAssertTrue(isDataFromCache)
                XCTAssertNotNil(dataResponse)
                XCTAssertNotNil(dataResponse.result)
                XCTAssertNotNil(dataResponse.data)
                exp.fulfill()
            }
        
        case .cacheAndServer:
            
            request.responseJSON(responseDataSource: responseDataSource) { (isDataFromCache, dataResponse) in
                // First time. Data should not be from cache. should from server
                XCTAssertFalse(isDataFromCache)
                XCTAssertNotNil(dataResponse)
                XCTAssertNotNil(dataResponse.result)
                XCTAssertNotNil(dataResponse.data)
                exp.fulfill()
            }
            
            self.waitForExpectationsWithCommonTimeout()
            
            let exp = self.expectation(description: "Request should succeed")
            request.responseJSON(responseDataSource: responseDataSource) { (isDataFromCache, dataResponse) in
                // This time data should be from cache.
                XCTAssertTrue(isDataFromCache)
                XCTAssertNotNil(dataResponse)
                XCTAssertNotNil(dataResponse.result)
                XCTAssertNotNil(dataResponse.data)
                exp.fulfill()
            }
            
        default:
            break
        }
        
        self.waitForExpectationsWithCommonTimeout()
    }
    
    func waitForExpectationsWithCommonTimeout() {
        self.waitForExpectationsWithCommonTimeoutUsingHandler { error in
            print("Error: \(error?.localizedDescription)")
        }
    }
    
    func waitForExpectationsWithCommonTimeoutUsingHandler(with handler: @escaping XCWaitCompletionHandler) {
        self.waitForExpectations(timeout: 30, handler: handler)
    }
}
