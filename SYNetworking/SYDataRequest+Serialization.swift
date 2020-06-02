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
    /// - Parameter CacheResponse: cache Response
    /// - Returns: true is send request , false It does not send the request
    
    func shouldSendRequest<T,U>(_ request: SYRequest, cacheResponse: DataResponse<T,U>) -> Bool
    
    
    /// Custom response cache, By Business Logic Layer to indicate the current cache needs to be updated
    ///
    /// - Parameter request: current request
    /// - Parameter response: current request response
    /// - Returns: if return true, will to update cache,otherwise not update
    
    func shouldUpdateCache<T,U>(_ request: SYRequest, response: DataResponse<T,U>) -> Bool
}

/// Custom parameter load Cache. Default is Self parameter

public struct CustomLoadCacheInfo {
    
    public var requestMethod: HTTPMethod?
    
    public var baseURLString:  String?
    
    public var requestURLString: String?
    
    public var requestParameters: [String: Any]?
    
    public var cacheKey: String?
    
    public init(requestMethod: HTTPMethod? = nil, baseURLString: String? = nil, requestURLString: String? = nil, requestParameters: [String: Any]? = nil, cacheKey: String? = nil) {
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
    public func response(_ completionHandler: @escaping (_ defaultDataResponse: AFDataResponse<Data?>) -> Void) -> Self {
        self.request?.validate().response { (defaultDataResponse:AFDataResponse<Data?>) in
            func requestFilter(_ defaultDataResponse: AFDataResponse<Data?>) {
                if let _ = defaultDataResponse.error {
                    self.requestFailedFilter(defaultDataResponse)
                } else {
                    self.requestCompleteFilter(defaultDataResponse)
                }
            }
            requestFilter(defaultDataResponse)
            completionHandler(defaultDataResponse)
        }
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
    public func response<T: DataResponseSerializerProtocol>(_ responseSerializer: T, completionHandler: @escaping (_ dataResponse: AFDataResponse<T.SerializedObject>) -> Void) -> Self {
        
        self.request?.validate().response(queue: self.responseQueue, responseSerializer: responseSerializer) { (dataResponse:AFDataResponse<T.SerializedObject>) in
            
            func generateValidateFailResponse(_ dataResponse:DataResponse<T.SerializedObject,AFError>,serverError: Error?) -> DataResponse<T.SerializedObject,AFError> {
                return DataResponse(request: dataResponse.request, response: dataResponse.response, data: dataResponse.data, metrics: dataResponse.metrics, serializationDuration: dataResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
            }
            
            var response = dataResponse
            switch dataResponse.result {
            case .success(let obj):
                let validate = self.validateResponseWhenRequestSuccess(obj)
                if !validate.0 {
                    response = generateValidateFailResponse(response, serverError: validate.1)
                }
            case .failure(_):
                break
            }
            self.requestFilter(response)
            completionHandler(response)
        }
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
    public func responseDataFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<Data,AFError>) -> Void) {
        self.generateResponseDataFromCache(customLoadCacheInfo,completionHandler: completionHandler)
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
    public func responseData(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: DataResponse<Data,AFError>) -> Void) -> Self {
        
        func loadCache(responseData: DataResponse<Data,AFError>) {
            completionHandler(true,responseData)
        }
        
        func generateValidateFailResponse(_ dataResponse: DataResponse<Data,AFError>, serverError: Error?) -> DataResponse<Data,AFError> {
            return DataResponse(request: dataResponse.request, response: dataResponse.response, data: dataResponse.data, metrics: dataResponse.metrics, serializationDuration: dataResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
        }
        
        func responseDataFromRequest() {
            self.request?.validate().responseData(queue: self.responseQueue,completionHandler: { dataResponse in
                var response = dataResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        switch responseDataSource {
        case .server:
            self.request?.validate().responseData(queue: self.responseQueue, completionHandler: { dataResponse in
                var response = dataResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            
            self.responseDataFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<Data,AFError>) in
                do {
                    loadCache(responseData: try loadCacheData())
                } catch _ {
                    responseDataFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseDataFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<Data,AFError>) in
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
            self.responseDataFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<Data,AFError>) in
                do {
                    let cacheResponse = try loadCacheData()
                    loadCache(responseData: cacheResponse)
                    let isSendRequest = customCacheRequest.shouldSendRequest(self, cacheResponse: cacheResponse)
                    if isSendRequest {
                        self.request?.validate().responseData(queue: self.responseQueue,completionHandler: { dataResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(self, response: dataResponse)
                            if isUpdateCache {
                                var response = dataResponse
                                switch response.result {
                                case .success(let obj):
                                    let validate = self.validateResponseWhenRequestSuccess(obj)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                case .failure(_):
                                    break
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
    
    public func responseStringFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<String,AFError>) -> Void) {
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
    public func responseString(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ stringResponse: DataResponse<String,AFError>) -> Void) -> Self {
        
        func loadCache(responseString: DataResponse<String,AFError>) {
            completionHandler(true,responseString)
        }
        
        func generateValidateFailResponse(_ stringResponse: DataResponse<String,AFError>, serverError: Error?) -> DataResponse<String,AFError> {
            return DataResponse(request: stringResponse.request, response: stringResponse.response, data: stringResponse.data, metrics: stringResponse.metrics, serializationDuration: stringResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
        }
        
        func responseStringFromRequest() {
            self.request?.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                var response = stringResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        switch responseDataSource {
        case .server:
            self.request?.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                var response = stringResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseStringFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<String,AFError>) in
                do {
                    loadCache(responseString: try loadCacheData())
                } catch _ {
                    responseStringFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseStringFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<String,AFError>) in
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
            self.responseStringFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<String,AFError>) in
                do {
                    let cacheResponse = try loadCacheData()
                    loadCache(responseString: cacheResponse)
                    let isSendRequest = customCacheRequest.shouldSendRequest(self, cacheResponse: cacheResponse)
                    if isSendRequest {
                        self.request?.validate().responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { stringResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(self, response: stringResponse)
                            if isUpdateCache {
                                var response = stringResponse
                                switch response.result {
                                case .success(let obj):
                                    let validate = self.validateResponseWhenRequestSuccess(obj)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                case .failure(_):
                                    break
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
    
    public func responseJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<Any,AFError>) -> Void) {
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
    public func responseJSON(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ jsonResponse: DataResponse<Any,AFError>) -> Void) -> Self {
        
        func loadCache(responseJSON: DataResponse<Any,AFError>) {
            completionHandler(true,responseJSON)
        }
        
        func responseJSONFromRequest() {
            self.request?.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                var response = jsonResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ jsonResponse: DataResponse<Any,AFError>, serverError: Error?) -> DataResponse<Any,AFError> {
            return DataResponse(request: jsonResponse.request, response: jsonResponse.response, data: jsonResponse.data, metrics: jsonResponse.metrics, serializationDuration: jsonResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
        }
        
        switch responseDataSource {
        case .server:
            self.request?.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                var response = jsonResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseJSONFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<Any,AFError>) in
                do {
                    loadCache(responseJSON: try loadCacheData())
                } catch _ {
                    responseJSONFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseJSONFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<Any,AFError>) in
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
            self.responseJSONFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<Any,AFError>) in
                do {
                    let cacheResponse = try loadCacheData()
                    loadCache(responseJSON: cacheResponse)
                    let isSendRequest = customCacheRequest.shouldSendRequest(self, cacheResponse: cacheResponse)
                    if isSendRequest {
                        self.request?.validate().responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { jsonResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(self, response: jsonResponse)
                            if isUpdateCache {
                                var response = jsonResponse
                                switch response.result {
                                case .success(let obj):
                                   let validate = self.validateResponseWhenRequestSuccess(obj)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                case .failure(_):
                                    break
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

//MARK: - SwiftyJSON

extension SYDataRequest {
    
    /// load response SwiftyJSON from cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache SwiftyJSON data
    /// - completionHandler: load cache completion handle
    
    public func responseSwiftyJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<JSON,AFError>) -> Void) {
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
    public func responseSwiftyJSON(responseDataSource: ResponseDataSource = .server, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ swiftyJSONResponse: DataResponse<JSON,AFError>) -> Void) -> Self {
        
        func loadCache(responseSwiftyJSON: DataResponse<JSON,AFError>) {
            completionHandler(true,responseSwiftyJSON)
        }
        
        func responseSwiftyJSONFromRequest() {
            self.request?.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                var response = swiftyJSONResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ swiftyJSONResponse: DataResponse<JSON,AFError>, serverError: Error?) -> DataResponse<JSON,AFError> {
            return DataResponse(request: swiftyJSONResponse.request, response: swiftyJSONResponse.response, data: swiftyJSONResponse.data, metrics: swiftyJSONResponse.metrics, serializationDuration: swiftyJSONResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
        }
        
        switch responseDataSource {
        case .server:
            self.request?.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                var response = swiftyJSONResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseSwiftyJSONFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<JSON,AFError>) in
                do {
                    loadCache(responseSwiftyJSON: try loadCacheData())
                } catch _ {
                    responseSwiftyJSONFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseSwiftyJSONFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<JSON,AFError>) in
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
            self.responseSwiftyJSONFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<JSON,AFError>) in
                do {
                    let cacheResponse = try loadCacheData()
                    loadCache(responseSwiftyJSON: cacheResponse)
                    let isSendRequest = customCacheRequest.shouldSendRequest(self, cacheResponse: cacheResponse)
                    if isSendRequest {
                        self.request?.validate().responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { swiftyJSONResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(self, response: swiftyJSONResponse)
                            if isUpdateCache {
                                var response = swiftyJSONResponse
                                switch response.result {
                                case .success(let obj):
                                    let validate = self.validateResponseWhenRequestSuccess(obj)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                case .failure(_):
                                    break
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
    
    public func responseObjectFromCache<T: Mappable>(mapToObject object: T? = nil, customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<T,AFError>) -> Void) {
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
    public func responseObject<T: Mappable>(responseDataSource: ResponseDataSource = .server, mapToObject object: T? = nil, completionHandler: @escaping (_ isDataFromCache: Bool, _ objectResponse: DataResponse<T,AFError>) -> Void) -> Self {
        
        func loadCache(responseObject: DataResponse<T,AFError>) {
            completionHandler(true,responseObject)
        }
        
        func responseObjectFromRequest() {
            self.request?.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                var response = objectResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ objectResponse: DataResponse<T,AFError>, serverError: Error?) -> DataResponse<T,AFError> {
            return DataResponse(request: objectResponse.request, response: objectResponse.response, data: objectResponse.data, metrics: objectResponse.metrics, serializationDuration: objectResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
        }
        
        switch responseDataSource {
        case .server:
            self.request?.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                var response = objectResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseObjectFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<T,AFError>) in
                do {
                    loadCache(responseObject: try loadCacheData())
                } catch _ {
                    responseObjectFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseObjectFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<T,AFError>) in
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
            self.responseObjectFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<T,AFError>) in
                do {
                    let cacheResponse = try loadCacheData()
                    loadCache(responseObject: cacheResponse)
                    let isSendRequest = customCacheRequest.shouldSendRequest(self, cacheResponse: cacheResponse)
                    if isSendRequest {
                        self.request?.validate().responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { objectResponse in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(self, response: objectResponse)
                            if isUpdateCache {
                                var response = objectResponse
                                switch response.result {
                                case .success(let obj):
                                    let validate = self.validateResponseWhenRequestSuccess(obj)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                case .failure(_):
                                    break
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
    
    public func responseObjectArrayFromCache<T: Mappable>(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<[T],AFError>) -> Void) {
        self.generateResponseObjectArrayFromCache(customLoadCacheInfo, completionHandler: completionHandler)
    }
    
    /// Adds a handler to be called once the request has finished.
    
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter keyPath: The key path where object mapping should be performed
    /// - parameter responseDataSource: Request's responseData source type, implementing different type responseData source type
    /// - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
    
    /// - returns: The request.
    
    @discardableResult
    public func responseObjectArray<T: Mappable>(responseDataSource: ResponseDataSource = .server, completionHandler: @escaping (_ isDataFromCache: Bool, _ objectArrayResponse: DataResponse<[T],AFError>) -> Void) -> Self {
        
        func loadCache(responseObjectArray: DataResponse<[T],AFError>) {
            completionHandler(true,responseObjectArray)
        }
        
        func responseObjectArrayFromRequest() {
            self.request?.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T],AFError>) in
                var response = objectArrayResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response, shouldSaveCache: true)
                completionHandler(false,response)
            })
        }
        
        func generateValidateFailResponse(_ objectArrayResponse: DataResponse<[T],AFError>, serverError: Error?) -> DataResponse<[T],AFError> {
            return DataResponse(request: objectArrayResponse.request, response: objectArrayResponse.response, data: objectArrayResponse.data, metrics: objectArrayResponse.metrics, serializationDuration: objectArrayResponse.serializationDuration, result: .failure(self.generateValidationFailureError(serverError)))
        }
        
        
        switch responseDataSource {
        case .server:
            self.request?.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T],AFError>) in
                var response = objectArrayResponse
                switch response.result {
                case .success(let obj):
                    let validate = self.validateResponseWhenRequestSuccess(obj)
                    if !validate.0 {
                        response = generateValidateFailResponse(response, serverError: validate.1)
                    }
                case .failure(_):
                    break
                }
                self.requestFilter(response)
                completionHandler(false,response)
            })
        case .cacheIfPossible:
            self.responseObjectArrayFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<[T],AFError>) in
                do {
                    loadCache(responseObjectArray: try loadCacheData())
                } catch _ {
                    responseObjectArrayFromRequest()
                }
            })
        case .cacheAndServer:
            self.responseObjectArrayFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<[T],AFError>) in
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
            self.responseObjectArrayFromCache(completionHandler: { (loadCacheData: () throws -> DataResponse<[T],AFError>) in
                do {
                    let cacheResponse = try loadCacheData()
                    loadCache(responseObjectArray: cacheResponse)
                    let isSendRequest = customCacheRequest.shouldSendRequest(self, cacheResponse: cacheResponse)
                    if isSendRequest {
                        self.request?.validate().responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (objectArrayResponse: DataResponse<[T],AFError>) in
                            let isUpdateCache = customCacheRequest.shouldUpdateCache(self, response: objectArrayResponse)
                            if isUpdateCache {
                                var response = objectArrayResponse
                                switch response.result {
                                case .success(let obj):
                                    let validate = self.validateResponseWhenRequestSuccess(obj)
                                    if !validate.0 {
                                        response = generateValidateFailResponse(response, serverError: validate.1)
                                    }
                                case .failure(_):
                                    break
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
    
    func generateValidationFailureError(_ serverError: Error?) -> AFError {
        if let sError = serverError {
            let afError = AFError.createURLRequestFailed(error: sError)
            return afError
        }
        enum ValidationStatusCode: Int {
            case invalid = -1
        }
        let requestValidationErrorDomain = "com.synetwork.request.validation"
        let validationFailureDescription = "Validation failure"
        
        let e = NSError(domain: requestValidationErrorDomain, code: ValidationStatusCode.invalid.rawValue, userInfo: [NSLocalizedDescriptionKey: validationFailureDescription])
        let error = AFError.createURLRequestFailed(error: e)
        return error
    }
    
    func requestFilter<T,U>(_ response: DataResponse<T,U>, shouldSaveCache: Bool = false) {
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
    
    func generateResponseDataFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ dataResponse: () throws -> DataResponse<Data,AFError>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let cacheData = try loadCacheData()
                let data = try DataResponseSerializer().serialize(request: nil, response: nil, data: cacheData, error: nil)
                let dataResponse = DataResponse<Data, AFError>(request: nil, response: nil, data: cacheData, metrics: nil, serializationDuration: 0, result: .success(data))
                completionHandler({dataResponse})
            } catch let error {
                completionHandler({throw error})
            }
        }
    }
    
    func generateResponseStringFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<String,AFError>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                let string = try StringResponseSerializer().serialize(request: nil, response: nil, data: data, error: nil)
                let stringResponse = DataResponse<String, AFError>(request: nil, response: nil, data: data, metrics: nil, serializationDuration: 0, result: .success(string))
                completionHandler({ return stringResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<Any,AFError>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let serialize = JSONResponseSerializer(options: cacheMetadata.responseJSONOptions)
                let json = try serialize.serialize(request: nil, response: nil, data: data, error: nil)
                
                let jsonResponse = DataResponse<Any,AFError>(request: nil, response: nil, data: data, metrics: nil, serializationDuration: 0, result: .success(json))
                completionHandler({ return jsonResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseSwiftyJSONFromCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<JSON,AFError>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let serialize = SwiftyJSONResponseSerializer(options: cacheMetadata.responseJSONOptions)
                let swiftyJson = try serialize.serialize(request: nil, response: nil, data: data, error: nil)
                
                let swiftyJSONResponse = DataResponse<JSON,AFError>(request: nil, response: nil, data: data, metrics: nil, serializationDuration: 0, result: .success(swiftyJson))
                completionHandler({ return swiftyJSONResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseObjectFromCache<T: Mappable>(mapToObject object: T? = nil, customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<T,AFError>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                
                let serialize = DataRequest.ObjectMapperSerializer(cacheMetadata.responseObjectKeyPath, mapToObject: object, context: cacheMetadata.responseObjectContext)
                
                let object = try serialize.serialize(request: nil, response: nil, data: data, error: nil)
                 
                let objectResponse = DataResponse<T,AFError>(request: nil, response: nil, data: data, metrics: nil, serializationDuration: 0, result: .success(object))
                
                completionHandler({ return objectResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
    
    func generateResponseObjectArrayFromCache<T: Mappable>(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> DataResponse<[T],AFError>) -> Void) {
        self.loadLocalCache(customLoadCacheInfo) { (loadCacheData: () throws -> Data) in
            do {
                let data = try loadCacheData()
                guard let cacheMetadata = self.cacheMetadata else {
                    completionHandler({ throw LoadCacheError.invalidMetadata })
                    return
                }
                let serialize = DataRequest.ObjectMapperArraySerializer(cacheMetadata.responseObjectKeyPath,context: cacheMetadata.responseObjectContext) as MappableArrayResponseSerializer<T>
                
                let objectArray = try serialize.serialize(request: nil, response: nil, data: data, error: nil)
                
                let objectArrayResponse = DataResponse<[T],AFError>(request: nil, response: nil, data: data, metrics: nil, serializationDuration: 0, result: .success(objectArray))
                
                completionHandler({ return objectArrayResponse })
            } catch let error {
                completionHandler({ throw error })
            }
        }
    }
}


