//
//  SYDataRequest+Serialization.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2016/11/25.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

/// Request's responseData source type, implementing different type responseData source type

public enum ResponseDataSource {
    
    /// - server: Normal request, the request does not need to cache data, default is normal type
    
    case server
    
    /// - cacheIfPossible: If the request does not cache direct request data,If the current request's cache exist, We will not send network requests, Will return directly to the cache data, This method will only cacheTimeInSeconds set to greater than 0 to store
    
    case cacheIfPossible
    
    /// - cacheAndServer: If the current cache request exist, Will return the cached data, Will return cache Data at first, then send request, Overwrite an existing cache, This method will only cacheTimeInSeconds set to greater than 0 to store
    
    case cacheAndServer
    
    /// - custom: Custom Cache, By implementing CacheCustomizable Protocol, through the service layer to tell whether the current cache to be updated
    
    case custom
}

/// CacheCustomizable protocol

public protocol CacheCustomizable {
    
    /// Custom Request cache operations From Business Logic Layer, indicating the need to send a request
    ///
    /// - Parameter request: current request
    /// - Returns: true is send request , false It does not send the request
    
    func shouldSendRequest(_ request: SYRequest) -> Bool
    
    
    /// Custom response cache, By Business Logic Layer to indicate the current cache needs to be updated
    ///
    /// - Parameter response: current request response
    /// - Returns: if return true, will to update cache,otherwise not update
    
    func shouldUpdateCache<T>(_ response: Alamofire.DataResponse<T>) -> Bool
}

/// Custom parameter load Cache. Default is Self parameter

public struct CustomLoadCacheInfo {
    
    public var requestMethod: Alamofire.HTTPMethod?
    
    public var baseURLString:  String?
    
    public var requestURLString: String?
    
    public var requestParameters: [String: Any]?
    
    public var cacheKey: String?
    
    public init(requestMethod: Alamofire.HTTPMethod? = nil, baseURLString: String? = nil, requestURLString: String? = nil, requestParameters: [String: Any]? = nil, cacheKey: String? = nil) {
        self.requestMethod = requestMethod
        self.baseURLString = baseURLString
        self.requestURLString = requestURLString
        self.requestParameters = requestParameters
        self.cacheKey = cacheKey
    }
}

/// assert message

fileprivate let message = "Must be implemented CacheCustomizable Protocol"

// MARK: - Default

extension SYDataRequest {
    
    /// Adds a handler to be called once the request has finished.
    
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func response(_ completionHandler: @escaping (_ defaultDataResponse: Alamofire.DefaultDataResponse) -> Void) -> Self {
        self.dataRequest.validate().response(queue: self.responseQueue, completionHandler: { (defaultDataResponse: Alamofire.DefaultDataResponse) in
            func requestFilter(_ defaultDataResponse: Alamofire.DefaultDataResponse) {
                if let _ = defaultDataResponse.error {
                    self.requestFailedFilter(defaultDataResponse)
                } else {
                    self.requestCompleteFilter(defaultDataResponse)
                }
            }
            requestFilter(defaultDataResponse)
            completionHandler(defaultDataResponse)
        })
        return self
    }
    
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    /// - parameter responseSerializer: The response serializer responsible for serializing the request, response,
    ///                                 and data.
    /// - parameter completionHandler:  The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func response<T: Alamofire.DataResponseSerializerProtocol>(_ responseSerializer: T, completionHandler: @escaping (_ dataResponse: Alamofire.DataResponse<T.SerializedObject>) -> Void) -> Self {
        self.dataRequest.validate().response(queue: self.responseQueue, responseSerializer: responseSerializer, completionHandler: { dataResponse in
            func generateValidateFailResponse(_ dataResponse: Alamofire.DataResponse<T.SerializedObject>, serverError: NSError?) -> Alamofire.DataResponse<T.SerializedObject> {
                let result = responseSerializer.serializeResponse(dataResponse.request,
                                                                  dataResponse.response,
                                                                  dataResponse.data,
                                                                  self.generateValidationFailureError(serverError))
                return Alamofire.DataResponse(request: dataResponse.request,
                                              response: dataResponse.response,
                                              data: dataResponse.data,
                                              result: result,
                                              timeline: dataResponse.timeline)
            }
            
            var response = dataResponse
            if dataResponse.result.isSuccess {
                let validate = self.validateResponseWhenRequestSuccess(response)
                if !validate.0 {
                    response = generateValidateFailResponse(response, serverError: validate.1)
                }
            }
            self.requestFilter(response)
            completionHandler(response)
        })
        return self
    }
}


//MARK: - Data

extension SYDataRequest {
    
    
    /// load response data from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache data
    ///
    /// - completionHandler: load cache completion handle
    
    public func responseDataFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<Data>) -> Void) {
        self.generateResponseDataFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    ///
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseData(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<Data>) -> Void) -> Self {
        
        func loadCache(responseData: Alamofire.DataResponse<Data>) {
            completionHandler(true,responseData)
        }
        
        func generateValidateFailResponse(_ dataResponse: Alamofire.DataResponse<Data>, serverError: NSError?) -> Alamofire.DataResponse<Data> {
            let result = DataRequest.serializeResponseData(response: dataResponse.response, data: dataResponse.data, error: self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: dataResponse.request,
                                          response: dataResponse.response,
                                          data: dataResponse.data,
                                          result: result,
                                          timeline: dataResponse.timeline)
        }
        
        func responseDataFromRequest() {
            self.dataRequest.validate().responseData(queue: self.responseQueue,completionHandler: { dataResponse in
                var response = dataResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseData(queue: self.responseQueue, completionHandler: { dataResponse in
                var response = dataResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseDataFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Data>) in
                do {
                    loadCache(responseData: try loadCacheData())
                } catch _ {
                    responseDataFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseDataFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Data>) in
                do {
                    loadCache(responseData: try loadCacheData())
                    responseDataFromRequest()
                } catch _ {
                    responseDataFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responseDataFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Data>) in
                do {
                    loadCache(responseData: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responseData(queue: self.responseQueue,completionHandler: { dataResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(dataResponse)
                            if isUpdateCache {
                                var response = dataResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response, shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responseDataFromRequest()
                }
            })
        }
        return self
    }
    
}

//MARK: - String

extension SYDataRequest {
    
    /// load response string from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache string data
    /// - completionHandler: load cache completion handle
    
    public func responseStringFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<String>) -> Void) {
        self.generateResponseStringFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    ///
    /// - parameter encoding:          The string encoding. If `nil`, the string encoding will be determined from the
    ///                                server response, falling back to the default HTTP default character set,
    ///                                ISO-8859-1.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseString(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ stringResponse: Alamofire.DataResponse<String>) -> Void) -> Self {
        
        func loadCache(responseString: Alamofire.DataResponse<String>) {
            completionHandler(true,responseString)
        }
        
        func generateValidateFailResponse(_ stringResponse: Alamofire.DataResponse<String>, serverError: NSError?) -> Alamofire.DataResponse<String> {
            let result = DataRequest.serializeResponseString(encoding: self.responseStringEncoding, response: stringResponse.response, data: stringResponse.data, error: self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: stringResponse.request,
                                          response: stringResponse.response,
                                          data: stringResponse.data,
                                          result: result,
                                          timeline: stringResponse.timeline)
        }
        
        func responseStringFromRequest() {
            self.dataRequest.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                var response = stringResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                var response = stringResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseStringFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<String>) in
                do {
                    loadCache(responseString: try loadCacheData())
                } catch _ {
                    responseStringFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseStringFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<String>) in
                do {
                    loadCache(responseString: try loadCacheData())
                    responseStringFromRequest()
                } catch _ {
                    responseStringFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responseStringFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<String>) in
                do {
                    loadCache(responseString: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(stringResponse)
                            if isUpdateCache {
                                var response = stringResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response, shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responseStringFromRequest()
                }
            })
        }
        return self
    }
    
}

//MARK: - JSON

extension SYDataRequest {
    
    /// load response JSON from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache JSON data
    /// - completionHandler: load cache completion handle
    
    public func responseJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<Any>) -> Void) {
        self.generateResponseJSONFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    ///
    /// - parameter options:           The JSON serialization reading options. Defaults to `.allowFragments`.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseJSON(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ jsonResponse: Alamofire.DataResponse<Any>) -> Void) -> Self {
        
        func loadCache(responseJSON: Alamofire.DataResponse<Any>) {
            completionHandler(true,responseJSON)
        }
        
        func responseJSONFromRequest() {
            self.dataRequest.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                var response = jsonResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ jsonResponse: Alamofire.DataResponse<Any>, serverError: NSError?) -> Alamofire.DataResponse<Any> {
            let result = DataRequest.serializeResponseJSON(options: self.responseJSONOptions, response: jsonResponse.response, data: jsonResponse.data, error: self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: jsonResponse.request,
                                          response: jsonResponse.response,
                                          data: jsonResponse.data,
                                          result: result,
                                          timeline: jsonResponse.timeline)
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                var response = jsonResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseJSONFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Any>) in
                do {
                    loadCache(responseJSON: try loadCacheData())
                } catch _ {
                    responseJSONFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseJSONFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Any>) in
                do {
                    loadCache(responseJSON: try loadCacheData())
                    responseJSONFromRequest()
                } catch _ {
                    responseJSONFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responseJSONFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Any>) in
                do {
                    loadCache(responseJSON: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(jsonResponse)
                            if isUpdateCache {
                                var response = jsonResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response,shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responseJSONFromRequest()
                }
            })
        }
        
        return self
    }
}

//MARK: - PropertyList

extension SYDataRequest {
    
    /// load response PropertyList from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache PropertyList data
    /// - completionHandler: load cache completion handle
    
    public func responsePropertyListFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<Any>) -> Void) {
        self.generateResponsePropertyListFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Creates a response serializer that returns an object constructed from the response data using
    /// `PropertyListSerialization` with the specified reading options.
    ///
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    ///
    /// - parameter options: The property list reading options. Defaults to `[]`.
    ///
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responsePropertyList(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool,_ propertyListResponse: Alamofire.DataResponse<Any>) -> Void) -> Self {
        
        func loadCache(responsePropertyList: Alamofire.DataResponse<Any>) {
            completionHandler(true,responsePropertyList)
        }
        
        func responsePropertyListFromRequest() {
            self.dataRequest.validate().responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { propertyListResponse in
                var response = propertyListResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ propertyListResponse: Alamofire.DataResponse<Any>, serverError: NSError?) -> Alamofire.DataResponse<Any> {
            let result = DataRequest.serializeResponsePropertyList(options: self.responsePropertyListOptions, response: propertyListResponse.response, data: propertyListResponse.data, error: self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: propertyListResponse.request,
                                          response: propertyListResponse.response,
                                          data: propertyListResponse.data,
                                          result: result,
                                          timeline: propertyListResponse.timeline)
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { propertyListResponse in
                var response = propertyListResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responsePropertyListFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Any>) in
                do {
                    loadCache(responsePropertyList: try loadCacheData())
                } catch _ {
                    responsePropertyListFromRequest()
                }
            })
        case .cacheAndServer:
            self.responsePropertyListFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Any>) in
                do {
                    loadCache(responsePropertyList: try loadCacheData())
                    responsePropertyListFromRequest()
                } catch _ {
                    responsePropertyListFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responsePropertyListFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<Any>) in
                do {
                    loadCache(responsePropertyList: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { propertyListResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(propertyListResponse)
                            if isUpdateCache {
                                var response = propertyListResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response, shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responsePropertyListFromRequest()
                }
            })
        }
        return self
    }
    
}

//MARK: - SwiftyJSON

extension SYDataRequest {
    
    /// load response SwiftyJSON from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache SwiftyJSON data
    /// - completionHandler: load cache completion handle
    
    public func responseSwiftyJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<JSON>) -> Void) {
        self.generateResponseSwiftyJSONFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter options: The JSON serialization reading options. Defaults to `.allowFragments`.
    ///
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    ///
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseSwiftyJSON(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ swiftyJSONResponse: Alamofire.DataResponse<JSON>) -> Void) -> Self {
        
        func loadCache(responseSwiftyJSON: Alamofire.DataResponse<JSON>) {
            completionHandler(true,responseSwiftyJSON)
        }
        
        func responseSwiftyJSONFromRequest() {
            self.dataRequest.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                var response = swiftyJSONResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ swiftyJSONResponse: Alamofire.DataResponse<JSON>, serverError: NSError?) -> Alamofire.DataResponse<JSON> {
            let result = DataRequest.serializeResponseSwiftyJSON(options: self.responseJSONOptions, response: swiftyJSONResponse.response, data: swiftyJSONResponse.data, error: self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: swiftyJSONResponse.request,
                                          response: swiftyJSONResponse.response,
                                          data: swiftyJSONResponse.data,
                                          result: result,
                                          timeline: swiftyJSONResponse.timeline)
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                var response = swiftyJSONResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseSwiftyJSONFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<JSON>) in
                do {
                    loadCache(responseSwiftyJSON: try loadCacheData())
                } catch _ {
                    responseSwiftyJSONFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseSwiftyJSONFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<JSON>) in
                do {
                    loadCache(responseSwiftyJSON: try loadCacheData())
                    responseSwiftyJSONFromRequest()
                } catch _ {
                    responseSwiftyJSONFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responseSwiftyJSONFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<JSON>) in
                do {
                    loadCache(responseSwiftyJSON: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(swiftyJSONResponse)
                            if isUpdateCache {
                                var response = swiftyJSONResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response,shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responseSwiftyJSONFromRequest()
                }
            })
        }
        return self
    }
}

//MARK: - ObjectMapper

extension SYDataRequest {
    
    
    /// load response Object from cache
    ///
    /// - object: An object to perform the mapping on to, When you need your request that you return a specified object，You can make your object implementation “Mappable”
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache Object data
    /// - completionHandler: load cache completion handle
    
    public func responseObjectFromCache<T: ObjectMapper.Mappable>(mapToObject object: T? = nil, customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<T>) -> Void) {
        self.generateResponseObjectFromCache(mapToObject: object, customLoadCacheInfo: customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue:             The queue on which the completion handler is dispatched.
     - parameter keyPath:           The key path where object mapping should be performed
     - parameter object:            An object to perform the mapping on to, When you need your request that you return a specified object，You can make your object implementation “Mappable”
     - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
     
     /* eg：
     struct Temperature: Mappable {
     var celsius: Double?
     var fahrenheit: Double?
     
     init?(map: Map) {
     
     }
     
     mutating func mapping(map: Map) {
     celsius     <- map["celsius"]
     fahrenheit  <- map["fahrenheit"]
     }
     }*/
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - parameter isDataFromCache: Whether data is from local cache. default is false
     
     - returns: The Request.
     */
    
    @discardableResult
    public func responseObject<T: ObjectMapper.Mappable>(responseDataSource: ResponseDataSource = .server, mapToObject object: T? = nil, completionHandler: @escaping (_ isDataFromCache: Bool, _ objectResponse: Alamofire.DataResponse<T>) -> Void) -> Self {
        
        func loadCache(responseObject: Alamofire.DataResponse<T>) {
            completionHandler(true,responseObject)
        }
        
        func responseObjectFromRequest() {
            self.dataRequest.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                var response = objectResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ objectResponse: Alamofire.DataResponse<T>, serverError: NSError?) -> Alamofire.DataResponse<T> {
            let responseSerializer = DataRequest.ObjectMapperSerializer(self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext)
            let result = responseSerializer.serializeResponse(objectResponse.request, objectResponse.response, objectResponse.data, self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: objectResponse.request,
                                          response: objectResponse.response,
                                          data: objectResponse.data,
                                          result: result,
                                          timeline: objectResponse.timeline)
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                var response = objectResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseObjectFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<T>) in
                do {
                    loadCache(responseObject: try loadCacheData())
                } catch _ {
                    responseObjectFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseObjectFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<T>) in
                do {
                    loadCache(responseObject: try loadCacheData())
                    responseObjectFromRequest()
                } catch _ {
                    responseObjectFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responseObjectFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<T>) in
                do {
                    loadCache(responseObject: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(objectResponse)
                            if isUpdateCache {
                                var response = objectResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response, shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responseObjectFromRequest()
                }
            })
        }
        return self
    }
    
    
    /// load response ObjectArray from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache ObjectArray data
    /// - completionHandler: load cache completion handle
    
    public func responseObjectArrayFromCache<T: ObjectMapper.Mappable>(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<[T]>) -> Void) {
        self.generateResponseObjectArrayFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Adds a handler to be called once the request has finished.
    
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter keyPath: The key path where object mapping should be performed
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    /// - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
    
    /// - returns: The request.
    
    @discardableResult
    public func responseObjectArray<T: ObjectMapper.Mappable>(responseDataSource: ResponseDataSource = .server, completionHandler: @escaping (_ isDataFromCache: Bool, _ objectArrayResponse: Alamofire.DataResponse<[T]>) -> Void) -> Self {
        
        func loadCache(responseObjectArray: Alamofire.DataResponse<[T]>) {
            completionHandler(true,responseObjectArray)
        }
        
        func responseObjectArrayFromRequest() {
            self.dataRequest.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T]>) in
                var response = objectArrayResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ objectArrayResponse: Alamofire.DataResponse<[T]>, serverError: NSError?) -> Alamofire.DataResponse<[T]> {
            let responseSerializer = DataRequest.ObjectMapperArraySerializer(self.responseObjectKeyPath, context: self.responseObjectContext) as DataResponseSerializer<[T]>
            let result = responseSerializer.serializeResponse(objectArrayResponse.request, objectArrayResponse.response, objectArrayResponse.data, self.generateValidationFailureError(serverError))
            return Alamofire.DataResponse(request: objectArrayResponse.request,
                                          response: objectArrayResponse.response,
                                          data: objectArrayResponse.data,
                                          result: result,
                                          timeline: objectArrayResponse.timeline)
        }
        
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T]>) in
                var response = objectArrayResponse
                if response.result.isSuccess {
                    let validate = self.validateResponseWhenRequestSuccess(response)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseObjectArrayFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<[T]>) in
                do {
                    loadCache(responseObjectArray: try loadCacheData())
                } catch _ {
                    responseObjectArrayFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseObjectArrayFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<[T]>) in
                do {
                    loadCache(responseObjectArray: try loadCacheData())
                    responseObjectArrayFromRequest()
                } catch _ {
                    responseObjectArrayFromRequest()
                }
            })
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                assertionFailure(message)
                return self
            }
            self.responseObjectArrayFromCache(completionHandler: { (loadCacheData: () throws -> Alamofire.DataResponse<[T]>) in
                do {
                    loadCache(responseObjectArray: try loadCacheData())
                    let isSendRequest = customCacheRequest.shouldSendRequest(self)
                    if isSendRequest {
                        self.dataRequest.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T]>) in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(objectArrayResponse)
                            if isUpdateCache {
                                var response = objectArrayResponse
                                if response.result.isSuccess {
                                    let validate = self.validateResponseWhenRequestSuccess(response)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                }
                                self.requestFilter(response, shouldSaveCache: true)
                                completionHandler(false,response)
                            }
                        })
                    }
                } catch _ {
                    responseObjectArrayFromRequest()
                }
            })
        }
        return self
    }
}

//MARK: - Private

private extension SYDataRequest {
    
    func generateValidationFailureError(_ serverError: NSError?) -> NSError {
        if let sError = serverError {
            return sError
        }
        enum ValidationStatusCode: Int {
            case invalid = -1
        }
        let requestValidationErrorDomain = "com.synetwork.request.validation"
        let validationFailureDescription = "Validation failure"
        
        return NSError(domain: requestValidationErrorDomain, code: ValidationStatusCode.invalid.rawValue, userInfo: [NSLocalizedDescriptionKey: validationFailureDescription])
    }
    
    func requestFilter<T>(_ response: Alamofire.DataResponse<T>, shouldSaveCache: Bool = false) {
        switch response.result {
        case .success(_):
            self.requestCompleteFilter(response)
            if shouldSaveCache {
                // save cache
                self.cacheToFile(response.data)
            }
        case .failure(_):
            self.requestFailedFilter(response)
        }
        
        if SYNetworkingConfig.sharedInstance.shouldPrintRequestLog {
            let description = response.responseDescriptionFormat(self)
            print("\(description)")
        }
    }
    
    func generateResponseDataFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<Data>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                let cacheResponse = DataRequest.serializeResponseData(response: nil, data: data, error: nil)
                let dataResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return dataResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseStringFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<String>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                let cacheResponse = DataRequest.serializeResponseString(encoding: self.cacheMetadata?.responseStringEncoding, response: nil, data: data, error: nil)
                let stringResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return stringResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<Any>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let cacheResponse = DataRequest.serializeResponseJSON(options:cacheMetadata.responseJSONOptions, response: nil, data: data, error: nil)
                let jsonResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return jsonResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponsePropertyListFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<Any>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let cacheResponse = DataRequest.serializeResponsePropertyList(options: cacheMetadata.responsePropertyListOptions, response: nil, data: data, error: nil)
                let propertyListResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return propertyListResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseSwiftyJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<JSON>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let cacheResponse = DataRequest.serializeResponseSwiftyJSON(options:cacheMetadata.responseJSONOptions, response: nil, data: data, error: nil)
                let swiftyJSONResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return swiftyJSONResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseObjectFromCache<T: ObjectMapper.Mappable>(mapToObject object: T? = nil, customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<T>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let responseSerializer = DataRequest.ObjectMapperSerializer(cacheMetadata.responseObjectKeyPath, mapToObject: object, context: cacheMetadata.responseObjectContext)
                let cacheResponse = responseSerializer.serializeResponse(nil, nil, data, nil)
                let objectResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return objectResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseObjectArrayFromCache<T: ObjectMapper.Mappable>(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Alamofire.DataResponse<[T]>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let responseSerializer = DataRequest.ObjectMapperArraySerializer(cacheMetadata.responseObjectKeyPath, context: cacheMetadata.responseObjectContext) as DataResponseSerializer<[T]>
                let cacheResponse = responseSerializer.serializeResponse(nil, nil, data, nil)
                let objectArrayResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
                completionHandler({ return objectArrayResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
}


