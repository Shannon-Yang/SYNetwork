//
//  SYDataRequest+Serialization.swift
//  SYNetwork
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
    
    public var baseUrlString:  String?
    
    public var requestUrlString: String?
    
    public var requestParameters: [String: Any]?
    
    public var cacheKey: String?
    
    public init(requestMethod: Alamofire.HTTPMethod? = nil, baseUrlString: String? = nil, requestUrlString: String? = nil, requestParameters: [String: Any]? = nil, cacheKey: String? = nil) {
        self.requestMethod = requestMethod
        self.baseUrlString = baseUrlString
        self.requestUrlString = requestUrlString
        self.requestParameters = requestParameters
        self.cacheKey = cacheKey
    }
}


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
            func generateValidateFailResponse(_ defaultDataResponse: Alamofire.DefaultDataResponse) -> Alamofire.DefaultDataResponse {
                if #available(iOS 10.0, *) {
                    return Alamofire.DefaultDataResponse(request: defaultDataResponse.request,
                                                         response: defaultDataResponse.response,
                                                         data: defaultDataResponse.data,
                                                         error: self.generateValidationFailureError(),
                                                         timeline: defaultDataResponse.timeline,
                                                         metrics: defaultDataResponse.metrics)
                }
                return Alamofire.DefaultDataResponse(request: defaultDataResponse.request,
                                                     response: defaultDataResponse.response,
                                                     data: defaultDataResponse.data,
                                                     error: self.generateValidationFailureError(),
                                                     timeline: defaultDataResponse.timeline)
            }
            var response = defaultDataResponse
            if !self.validateResponse(response) {
                response = generateValidateFailResponse(response)
            }
            requestFilter(response)
            completionHandler(response)
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
            func generateValidateFailResponse(_ dataResponse: Alamofire.DataResponse<T.SerializedObject>) -> Alamofire.DataResponse<T.SerializedObject> {
                let result = responseSerializer.serializeResponse(dataResponse.request,
                                                                  dataResponse.response,
                                                                  dataResponse.data,
                                                                  self.generateValidationFailureError())
                return Alamofire.DataResponse(request: dataResponse.request,
                                              response: dataResponse.response,
                                              data: dataResponse.data,
                                              result: result,
                                              timeline: dataResponse.timeline)
            }
            
            var response = dataResponse
            if !self.validateResponse(response) {
                response = generateValidateFailResponse(response)
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
    /// - Throws: cache load error type
    
    public func responseDataFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<Data> {
        do {
            return try self.generateResponseDataFromCache()
        } catch let error {
            throw error
        }
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
        
        func loadCache() throws {
            do {
                let responseData = try self.responseDataFromCache()
                self.requestFilter(responseData)
                completionHandler(true,responseData)
            } catch let error {
                throw error
            }
        }
        
        func generateValidateFailResponse(_ dataResponse: Alamofire.DataResponse<Data>) -> Alamofire.DataResponse<Data> {
            let result = DataRequest.serializeResponseData(response: dataResponse.response, data: dataResponse.data, error: self.generateValidationFailureError())
            return Alamofire.DataResponse(request: dataResponse.request,
                                          response: dataResponse.response,
                                          data: dataResponse.data,
                                          result: result,
                                          timeline: dataResponse.timeline)
        }
        
        func responseDataFromRequest() {
            self.dataRequest.validate().responseData(queue: self.responseQueue,completionHandler: { dataResponse in
                var response = dataResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseData(queue: self.responseQueue, completionHandler: { dataResponse in
                var response = dataResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responseDataFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responseDataFromRequest()
            } catch _ {
                responseDataFromRequest()
            }
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responseData(queue: self.responseQueue,completionHandler: { dataResponse in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(dataResponse)
                        if isUpdateCache {
                            var response = dataResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responseDataFromRequest()
            }
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
    /// - Throws: cache load error type
    
    public func responseStringFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<String> {
        do {
            return try self.generateResponseStringFromCache()
        } catch let error {
            throw error
        }
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
        
        func loadCache() throws {
            do {
                let responseString = try self.responseStringFromCache()
                self.requestFilter(responseString)
                completionHandler(true,responseString)
            } catch let error {
                throw error
            }
        }
        
        func generateValidateFailResponse(_ stringResponse: Alamofire.DataResponse<String>) -> Alamofire.DataResponse<String> {
            let result = DataRequest.serializeResponseString(encoding: self.responseStringEncoding, response: stringResponse.response, data: stringResponse.data, error: self.generateValidationFailureError())
            return Alamofire.DataResponse(request: stringResponse.request,
                                          response: stringResponse.response,
                                          data: stringResponse.data,
                                          result: result,
                                          timeline: stringResponse.timeline)
        }
        
        func responseStringFromRequest() {
            self.dataRequest.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                var response = stringResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        switch responseDataSource {
        case .server:
            self.dataRequest.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                var response = stringResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responseStringFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responseStringFromRequest()
            } catch _ {
                responseStringFromRequest()
            }
            
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(stringResponse)
                        if isUpdateCache {
                            var response = stringResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responseStringFromRequest()
            }
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
    /// - Throws: cache load error type
    
    public func responseJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<Any> {
        do {
            return try self.generateResponseJSONFromCache()
        } catch let error {
            throw error
        }
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
        
        func loadCache() throws {
            do {
                let responseJSON = try self.responseJSONFromCache()
                self.requestFilter(responseJSON)
                completionHandler(true,responseJSON)
            } catch let error {
                throw error
            }
        }
        
        func responseJSONFromRequest() {
            self.dataRequest.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                var response = jsonResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ jsonResponse: Alamofire.DataResponse<Any>) -> Alamofire.DataResponse<Any> {
            let result = DataRequest.serializeResponseJSON(options: self.responseJSONOptions, response: jsonResponse.response, data: jsonResponse.data, error: self.generateValidationFailureError())
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
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responseJSONFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responseJSONFromRequest()
            } catch _ {
                responseJSONFromRequest()
            }
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(jsonResponse)
                        if isUpdateCache {
                            var response = jsonResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responseJSONFromRequest()
            }
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
    /// - Throws: cache load error type
    
    public func responsePropertyListFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<Any> {
        do {
            return try self.generateResponsePropertyListFromCache()
        } catch let error {
            throw error
        }
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
        
        func loadCache() throws {
            do {
                let responsePropertyList = try self.responsePropertyListFromCache()
                self.requestFilter(responsePropertyList)
                completionHandler(true,responsePropertyList)
            } catch let error {
                throw error
            }
        }
        
        func responsePropertyListFromRequest() {
            self.dataRequest.validate().responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { propertyListResponse in
                var response = propertyListResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ propertyListResponse: Alamofire.DataResponse<Any>) -> Alamofire.DataResponse<Any> {
            let result = DataRequest.serializeResponsePropertyList(options: self.responsePropertyListOptions, response: propertyListResponse.response, data: propertyListResponse.data, error: self.generateValidationFailureError())
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
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responsePropertyListFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responsePropertyListFromRequest()
            } catch _ {
                responsePropertyListFromRequest()
            }
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { propertyListResponse in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(propertyListResponse)
                        if isUpdateCache {
                            var response = propertyListResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responsePropertyListFromRequest()
            }
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
    /// - Throws: cache load error type
    
    public func responseSwiftyJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<JSON> {
        do {
            return try self.generateResponseSwiftyJSONFromCache()
        } catch let error {
            throw error
        }
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
        
        func loadCache() throws {
            do {
                let responseSwiftyJSON = try self.responseSwiftyJSONFromCache()
                self.requestFilter(responseSwiftyJSON)
                completionHandler(true,responseSwiftyJSON)
            } catch let error {
                throw error
            }
        }
        
        func responseSwiftyJSONFromRequest() {
            self.dataRequest.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                var response = swiftyJSONResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ swiftyJSONResponse: Alamofire.DataResponse<JSON>) -> Alamofire.DataResponse<JSON> {
            let result = DataRequest.serializeResponseSwiftyJSON(options: self.responseJSONOptions, response: swiftyJSONResponse.response, data: swiftyJSONResponse.data, error: self.generateValidationFailureError())
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
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responseSwiftyJSONFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responseSwiftyJSONFromRequest()
            } catch _ {
                responseSwiftyJSONFromRequest()
            }
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(swiftyJSONResponse)
                        if isUpdateCache {
                            var response = swiftyJSONResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responseSwiftyJSONFromRequest()
            }
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
    /// - Throws: cache load error type
    
    public func responseObjectFromCache<T: ObjectMapper.Mappable>(mapToObject object: T? = nil, customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<T> {
        do {
            return try self.generateResponseObjectFromCache(mapToObject: object)
        } catch let error {
            throw error
        }
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
        
        func loadCache() throws {
            do {
                let responseObject = try self.responseObjectFromCache(mapToObject: object)
                completionHandler(true,responseObject)
            } catch let error {
                throw error
            }
        }
        
        func responseObjectFromRequest() {
            self.dataRequest.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                var response = objectResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ objectResponse: Alamofire.DataResponse<T>) -> Alamofire.DataResponse<T> {
            let responseSerializer = DataRequest.ObjectMapperSerializer(self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext)
            let result = responseSerializer.serializeResponse(objectResponse.request, objectResponse.response, objectResponse.data, self.generateValidationFailureError())
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
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responseObjectFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responseObjectFromRequest()
            } catch _ {
                responseObjectFromRequest()
            }
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(objectResponse)
                        if isUpdateCache {
                            var response = objectResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responseObjectFromRequest()
            }
        }
        return self
    }
    
    
    /// load response ObjectArray from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache ObjectArray data
    /// - Throws: cache load error type
    
    public func responseObjectArrayFromCache<T: ObjectMapper.Mappable>(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<[T]> {
        do {
            return try self.generateResponseObjectArrayFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter keyPath: The key path where object mapping should be performed
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    /// - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
    
    /// - returns: The request.
    
    @discardableResult
    public func responseObjectArray<T: ObjectMapper.Mappable>(responseDataSource: ResponseDataSource = .server, completionHandler: @escaping (_ isDataFromCache: Bool, _ objectArrayResponse: Alamofire.DataResponse<[T]>) -> Void) -> Self {
        
        func loadCache() throws {
            do {
                let responseObjectArray = try self.responseObjectArrayFromCache() as DataResponse<[T]>
                self.requestFilter(responseObjectArray)
                completionHandler(true,responseObjectArray)
            } catch let error {
                throw error
            }
        }
        
        func responseObjectArrayFromRequest() {
            self.dataRequest.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T]>) in
                var response = objectArrayResponse
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ objectArrayResponse: Alamofire.DataResponse<[T]>) -> Alamofire.DataResponse<[T]> {
            let responseSerializer = DataRequest.ObjectMapperArraySerializer(self.responseObjectKeyPath, context: self.responseObjectContext) as DataResponseSerializer<[T]>
            let result = responseSerializer.serializeResponse(objectArrayResponse.request, objectArrayResponse.response, objectArrayResponse.data, self.generateValidationFailureError())
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
                if !self.validateResponse(response) {
                    response = generateValidateFailResponse(response)
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            do {
                try loadCache()
            } catch _ {
                responseObjectArrayFromRequest()
            }
        case .cacheAndServer:
            do {
                try loadCache()
                responseObjectArrayFromRequest()
            } catch _ {
                responseObjectArrayFromRequest()
            }
        case .custom:
            guard let customCacheRequest = self as? CacheCustomizable else {
                print("must be implemented CacheCustomizable protocol")
                return self
            }
            
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.shouldSendRequest(self)
                if isSendRequest {
                    self.dataRequest.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T]>) in
                        let isUpdateCache = customCacheRequest.shouldUpdateCache(objectArrayResponse)
                        if isUpdateCache {
                            var response = objectArrayResponse
                            if !self.validateResponse(response) {
                                response = generateValidateFailResponse(response)
                            }
                            self.requestFilter(response)
                            completionHandler(false,response)
                        }
                    })
                }
            } catch _ {
                responseObjectArrayFromRequest()
            }
        }
        return self
    }
}

//MARK: - Private

private extension SYDataRequest {
    
    func generateValidationFailureError() -> NSError {
        enum ValidationStatusCode: Int {
            case invalid = -1
        }
        let requestValidationErrorDomain = "com.synetwork.request.validation"
        let validationFailureDescription = "Validation failure"
        
        return NSError(domain: requestValidationErrorDomain, code: ValidationStatusCode.invalid.rawValue, userInfo: [NSLocalizedDescriptionKey: validationFailureDescription])
    }
    
    func requestFilter<T>(_ response: Alamofire.DataResponse<T>) {
        switch response.result {
        case .success(_):
            self.requestCompleteFilter(response)
            // save cache
            self.cacheToFile(response.data)
        case .failure(_):
            self.requestFailedFilter(response)
        }
    }
    
    func generateResponseDataFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<Data> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            let cacheResponse = DataRequest.serializeResponseData(response: nil, data: data, error: nil)
            let dataResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return dataResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseStringFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<String> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            let cacheResponse = DataRequest.serializeResponseString(encoding: self.cacheMetadata?.responseStringEncoding, response: nil, data: data, error: nil)
            let stringResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return stringResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<Any> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            guard let cacheMetadata = self.cacheMetadata else {
                throw LoadCacheError.invalidMetadata
            }
            let cacheResponse = DataRequest.serializeResponseJSON(options:cacheMetadata.responseJSONOptions, response: nil, data: data, error: nil)
            let jsonResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return jsonResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponsePropertyListFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<Any> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            guard let cacheMetadata = self.cacheMetadata else {
                throw LoadCacheError.invalidMetadata
            }
            let cacheResponse = DataRequest.serializeResponsePropertyList(options: cacheMetadata.responsePropertyListOptions, response: nil, data: data, error: nil)
            let propertyListResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return propertyListResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseSwiftyJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<JSON> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            guard let cacheMetadata = self.cacheMetadata else {
                throw LoadCacheError.invalidMetadata
            }
            let cacheResponse = DataRequest.serializeResponseSwiftyJSON(options:cacheMetadata.responseJSONOptions, response: nil, data: data, error: nil)
            let swiftyJSONResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return swiftyJSONResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseObjectFromCache<T: ObjectMapper.Mappable>(mapToObject object: T? = nil, customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<T> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            guard let cacheMetadata = self.cacheMetadata else {
                throw LoadCacheError.invalidMetadata
            }
            let responseSerializer = DataRequest.ObjectMapperSerializer(cacheMetadata.responseObjectKeyPath, mapToObject: object, context: cacheMetadata.responseObjectContext)
            let cacheResponse = responseSerializer.serializeResponse(nil, nil, data, nil)
            let objectResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return objectResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseObjectArrayFromCache<T: ObjectMapper.Mappable>(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) throws -> Alamofire.DataResponse<[T]> {
        do {
            let data = try self.loadLocalCache(customLoadCacheInfo)
            guard let cacheMetadata = self.cacheMetadata else {
                throw LoadCacheError.invalidMetadata
            }
            let responseSerializer = DataRequest.ObjectMapperArraySerializer(cacheMetadata.responseObjectKeyPath, context: cacheMetadata.responseObjectContext) as DataResponseSerializer<[T]>
            let cacheResponse = responseSerializer.serializeResponse(nil, nil, data, nil)
            let objectArrayResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return objectArrayResponse
        } catch let errror {
            throw errror
        }
    }
    
}


