//
//  YTResponseSerialization.swift
//  YTNetwork
//
//  Created by Shannon Yang on 2016/11/25.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

/// Request's cache tactics type, implementing different type cache tactics type

public enum YTCacheTactics {
    
    /// - `default`: Normal request, the request does not need to cache data, default is normal type
    
    case `default`
    
    /// - notSendRequetIfCacheExist: If the request does not cache direct request data,If the current request's cache exist, We will not send network requests, Will return directly to the cache data, This method will only cacheTimeInSeconds set to greater than 0 to store
    
    case notSendRequetIfCacheExist
    
    /// - seedRequestIfCacheExist: If the current cache request exist, Will return the cached data, Will return cache Data at first, then send request, Overwrite an existing cache, This method will only cacheTimeInSeconds set to greater than 0 to store
    
    case seedRequestIfCacheExist
    
    /// -customCacheTactics: Custom Cache Tactics, By implementing CacheTacticsCustomizable Protocol, through the service layer to tell whether the current cache to be updated
    
    case customCacheTactics
}

/// CustomCacheTactics protocol

public protocol CacheTacticsCustomizable {
    
    
    /// Custom Request cache operations From Business Logic Layer, indicating the need to send a request
    ///
    /// - Parameter request: current request
    /// - Returns: true is send request , false It does not send the request
    
    func customRequestCacheHandleFromBusinessLogicLayer(with request: YTRequest) -> Bool
    
    
    /// Custom response cache, By Business Logic Layer to indicate the current cache needs to be updated
    ///
    /// - Parameter response: current request response
    /// - Returns: if return true, will to update cache,otherwise not update
    
    func customResponseCacheHandleFromBusinessLogicLayer<T>(with response: Alamofire.DataResponse<T>) -> Bool
}


// MARK: - Default

extension YTDataRequest {
    
    /// Adds a handler to be called once the request has finished.
    
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func response(_ completionHandler: @escaping (_ defaultDataResponse: Alamofire.DefaultDataResponse) -> Void) -> Self {
        self.dataRequest.response(queue: self.responseQueue, completionHandler: completionHandler)
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
        self.dataRequest.response(queue: self.responseQueue, responseSerializer: responseSerializer, completionHandler: completionHandler)
        return self
    }
}

extension YTDownloadRequest {
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func response(_ completionHandler: @escaping (Alamofire.DefaultDownloadResponse) -> Void)
        -> Self {
            self.downloadRequest.response(queue: self.downloadQueue, completionHandler: completionHandler)
            return self
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    /// - parameter responseSerializer: The response serializer responsible for serializing the request, response,
    ///                                 and data contained in the destination url.
    /// - parameter completionHandler:  The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func response<T: DownloadResponseSerializerProtocol>(_ responseSerializer: T, completionHandler: @escaping (Alamofire.DownloadResponse<T.SerializedObject>) -> Void)
        -> Self {
            self.downloadRequest.response(queue: self.downloadQueue, responseSerializer: responseSerializer, completionHandler: completionHandler)
            return self
    }
}


//MARK: - Data

extension YTDataRequest {
    
    
    /// load response data from cache
    ///
    /// - Returns: cache data
    /// - Throws: cache load error type
    
    public func responseDataFromCache() throws -> Alamofire.DataResponse<Data> {
        do {
            return try self.generateResponseDataFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter cacheTactics: Request's cache tactics type, implementing different type cache tactics type
    ///
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseData(cacheTactics: YTCacheTactics = .`default`, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<Data>) -> Void) -> Self {
        
        func responseDataFromRequest() {
            self.dataRequest.responseData(queue: self.responseQueue,completionHandler: { response in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responseData = try self.responseDataFromCache()
                completionHandler(true,responseData)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responseData(queue: self.responseQueue, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responseDataFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responseDataFromRequest()
            } catch _ {
                responseDataFromRequest()
            }
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            do {
                try loadCache()
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responseData(queue: self.responseQueue,completionHandler: { response in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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

extension YTDownloadRequest {
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseData(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (Alamofire.DownloadResponse<Data>) -> Void)
        -> Self
    {
        self.downloadRequest.responseData(queue: self.downloadQueue, completionHandler: completionHandler)
        return self
    }
    
}


//MARK: - String

extension YTDataRequest {
    
    /// load response string from cache
    ///
    /// - Returns: cache string data
    /// - Throws: cache load error type
    
    public func responseStringFromCache() throws -> Alamofire.DataResponse<String> {
        do {
            return try self.generateResponseStringFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter cacheTactics: Request's cache tactics type, implementing different type cache tactics type
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
    public func responseString(cacheTactics: YTCacheTactics = .`default`, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<String>) -> Void) -> Self {
        func responseStringFromRequest() {
            self.dataRequest.responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { response in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responseString = try self.responseStringFromCache()
                completionHandler(true,responseString)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responseStringFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responseStringFromRequest()
            } catch _ {
                responseStringFromRequest()
            }
            
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            
            do {
                let responseString = try self.responseStringFromCache()
                completionHandler(true,responseString)
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responseString(queue: self.responseQueue, encoding: self.responseStringEncoding, completionHandler: { response in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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

extension YTDownloadRequest {
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter encoding:          The string encoding. If `nil`, the string encoding will be determined from the
    ///                                server response, falling back to the default HTTP default character set,
    ///                                ISO-8859-1.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseString(_ completionHandler: @escaping (Alamofire.DownloadResponse<String>) -> Void)
        -> Self
    {
        self.downloadRequest.responseString(queue: self.downloadQueue, encoding: self.downloadStringEncoding, completionHandler: completionHandler)
        return self
    }
}

//MARK: - JSON

extension YTDataRequest {
    
    /// load response JSON from cache
    ///
    /// - Returns: cache JSON data
    /// - Throws: cache load error type
    
    public func responseJSONFromCache() throws -> Alamofire.DataResponse<Any> {
        do {
            return try self.generateResponseJSONFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter cacheTactics: Request's cache tactics type, implementing different type cache tactics type
    ///
    /// - parameter options:           The JSON serialization reading options. Defaults to `.allowFragments`.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseJSON(cacheTactics: YTCacheTactics = .`default`, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<Any>) -> Void) -> Self {
        
        func responseJSONFromRequest() {
            self.dataRequest.responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { response in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responseJSON = try self.responseJSONFromCache()
                completionHandler(true,responseJSON)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responseJSONFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responseJSONFromRequest()
            } catch _ {
                responseJSONFromRequest()
            }
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            
            do {
                let responseJSON = try self.responseJSONFromCache()
                completionHandler(true,responseJSON)
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responseJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { response in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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

extension YTDownloadRequest {
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter options:           The JSON serialization reading options. Defaults to `.allowFragments`.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseJSON(_ completionHandler: @escaping (Alamofire.DownloadResponse<Any>) -> Void)
        -> Self
    {
        self.downloadRequest.responseJSON(queue: self.downloadQueue, options: self.downloadJSONOptions, completionHandler: completionHandler)
        return self
    }
}

//MARK: - PropertyList

extension YTDataRequest {
    
    /// load response PropertyList from cache
    ///
    /// - Returns: cache PropertyList data
    /// - Throws: cache load error type
    
    public func responsePropertyListFromCache() throws -> Alamofire.DataResponse<Any> {
        do {
            return try self.generateResponsePropertyListFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Creates a response serializer that returns an object constructed from the response data using
    /// `PropertyListSerialization` with the specified reading options.
    ///
    /// - parameter cacheTactics: Request's cache tactics type, implementing different type cache tactics type
    ///
    /// - parameter options: The property list reading options. Defaults to `[]`.
    ///
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - parameter isDataFromCache: Whether data is from local cache. default is false
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responsePropertyList(cacheTactics: YTCacheTactics = .`default`, _ completionHandler: @escaping (_ isDataFromCache: Bool,_ dataResponse: Alamofire.DataResponse<Any>) -> Void) -> Self {
        
        func responsePropertyListFromRequest() {
            self.dataRequest.responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { response in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responsePropertyList = try self.responsePropertyListFromCache()
                completionHandler(true,responsePropertyList)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responsePropertyListFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responsePropertyListFromRequest()
            } catch _ {
                responsePropertyListFromRequest()
            }
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            
            do {
                let responsePropertyList = try self.responsePropertyListFromCache()
                completionHandler(true,responsePropertyList)
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responsePropertyList(queue: self.responseQueue, options: self.responsePropertyListOptions, completionHandler: { response in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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

extension YTDownloadRequest {
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter options:           The property list reading options. Defaults to `[]`.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responsePropertyList(
        queue: DispatchQueue? = nil,
        options: PropertyListSerialization.ReadOptions = [],
        completionHandler: @escaping (Alamofire.DownloadResponse<Any>) -> Void)
        -> Self
    {
        self.downloadRequest.responsePropertyList(queue: self.downloadQueue, options: self.downloadPropertyListOptions, completionHandler: completionHandler)
        return self
    }
}

//MARK: - SwiftyJSON

extension YTDataRequest {
    
    /// load response SwiftyJSON from cache
    ///
    /// - Returns: cache SwiftyJSON data
    /// - Throws: cache load error type
    
    public func responseSwiftyJSONFromCache() throws -> Alamofire.DataResponse<JSON> {
        do {
            return try self.generateResponseSwiftyJSONFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter options: The JSON serialization reading options. Defaults to `.allowFragments`.
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func responseSwiftyJSON(cacheTactics: YTCacheTactics = .`default`, _ completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<JSON>) -> Void) -> Self {
        
        func responseSwiftyJSONFromRequest() {
            self.dataRequest.responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { response in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responseSwiftyJSON = try self.responseSwiftyJSONFromCache()
                completionHandler(true,responseSwiftyJSON)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responseSwiftyJSONFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responseSwiftyJSONFromRequest()
            } catch _ {
                responseSwiftyJSONFromRequest()
            }
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            
            do {
                let responseSwiftyJSON = try self.responseSwiftyJSONFromCache()
                completionHandler(true,responseSwiftyJSON)
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responseSwiftyJSON(queue: self.responseQueue, options: self.responseJSONOptions, completionHandler: { response in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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

extension YTDataRequest {
    
    
    /// load response Object from cache
    ///
    /// - Returns: cache Object data
    /// - Throws: cache load error type
    
    public func responseObjectFromCache<T: BaseMappable>(mapToObject object: T?) throws -> Alamofire.DataResponse<T> {
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
     - parameter object:            An object to perform the mapping on to, When you need your request that you return a specified object，You can make your object implementation “Mappable”，
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
    public func responseObject<T: ObjectMapper.BaseMappable>(cacheTactics: YTCacheTactics = .`default`, mapToObject object: T? = nil, completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<T>) -> Void) -> Self {
        
        func responseObjectFromRequest() {
            self.dataRequest.responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { response in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responseObject = try self.responseObjectFromCache(mapToObject: object)
                completionHandler(true,responseObject)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responseObjectFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responseObjectFromRequest()
            } catch _ {
                responseObjectFromRequest()
            }
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            
            do {
                let responseObject = try self.responseObjectFromCache(mapToObject: object)
                completionHandler(true,responseObject)
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responseObject(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, mapToObject: object, context: self.responseObjectContext, completionHandler: { response in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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
    /// - Returns: cache ObjectArray data
    /// - Throws: cache load error type
    
    public func responseObjectArrayFromCache<T: BaseMappable>() throws -> Alamofire.DataResponse<[T]> {
        do {
            return try self.generateResponseObjectArrayFromCache()
        } catch let error {
            throw error
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    
    /// - parameter queue: The queue on which the completion handler is dispatched.
    /// - parameter keyPath: The key path where object mapping should be performed
    /// - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
    
    /// - returns: The request.
    
    @discardableResult
    public func responseObjectArray<T: ObjectMapper.BaseMappable>(cacheTactics: YTCacheTactics = .`default`, completionHandler: @escaping (_ isDataFromCache: Bool, _ dataResponse: Alamofire.DataResponse<[T]>) -> Void) -> Self {
        
        func responseObjectArrayFromRequest() {
            self.dataRequest.responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (response: DataResponse<[T]>) in
                if response.result.isSuccess {
                    self.saveResponseDataToCacheFile(with: response.data)
                }
                completionHandler(false,response)
            })
        }
        
        func loadCache() throws {
            do {
                let responseObjectArray = try self.responseObjectArrayFromCache() as DataResponse<[T]>
                completionHandler(true,responseObjectArray)
            } catch let error {
                throw error
            }
        }
        
        switch cacheTactics {
        case .`default`:
            self.dataRequest.responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { response in
                completionHandler(false,response)
            })
        case .notSendRequetIfCacheExist:
            do {
                try loadCache()
            } catch _ {
                responseObjectArrayFromRequest()
            }
        case .seedRequestIfCacheExist:
            do {
                try loadCache()
                responseObjectArrayFromRequest()
            } catch _ {
                responseObjectArrayFromRequest()
            }
        case .customCacheTactics:
            guard let customCacheRequest = self as? CacheTacticsCustomizable else {
                print("must be implemented CacheTacticsCustomizable protocol")
                return self
            }
            
            do {
                let responseObjectArray = try self.responseObjectArrayFromCache() as DataResponse<[T]>
                completionHandler(true,responseObjectArray)
                let isSendRequest = customCacheRequest.customRequestCacheHandleFromBusinessLogicLayer(with: self)
                if isSendRequest {
                    self.dataRequest.responseArray(queue: self.responseQueue, keyPath: self.responseObjectKeyPath, context: self.responseObjectContext, completionHandler: { (response: DataResponse<[T]>) in
                        let isUpdateCache = customCacheRequest.customResponseCacheHandleFromBusinessLogicLayer(with: response)
                        if isUpdateCache {
                            if response.result.isSuccess {
                                self.saveResponseDataToCacheFile(with: response.data)
                            }
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

private extension YTDataRequest {
    
    func generateResponseDataFromCache() throws -> Alamofire.DataResponse<Data> {
        do {
            let data = try self.loadLocalCache()
            let cacheResponse = DataRequest.serializeResponseData(response: nil, data: data, error: nil)
            let dataResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return dataResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseStringFromCache() throws -> Alamofire.DataResponse<String> {
        do {
            let data = try self.loadLocalCache()
            let cacheResponse = DataRequest.serializeResponseString(encoding: self.cacheMetadata?.responseStringEncoding, response: nil, data: data, error: nil)
            let stringResponse = DataResponse(request: nil, response: nil, data: data, result: cacheResponse)
            return stringResponse
        } catch let errror {
            throw errror
        }
    }
    
    func generateResponseJSONFromCache() throws -> Alamofire.DataResponse<Any> {
        do {
            let data = try self.loadLocalCache()
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
    
    func generateResponsePropertyListFromCache() throws -> Alamofire.DataResponse<Any> {
        do {
            let data = try self.loadLocalCache()
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
    
    func generateResponseSwiftyJSONFromCache() throws -> Alamofire.DataResponse<JSON> {
        do {
            let data = try self.loadLocalCache()
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
    
    func generateResponseObjectFromCache<T: ObjectMapper.BaseMappable>(mapToObject object: T?) throws -> Alamofire.DataResponse<T> {
        do {
            let data = try self.loadLocalCache()
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
    
    func generateResponseObjectArrayFromCache<T: ObjectMapper.BaseMappable>() throws -> Alamofire.DataResponse<[T]> {
        do {
            let data = try self.loadLocalCache()
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


