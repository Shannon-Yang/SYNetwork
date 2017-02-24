//
//  SYDownloadRequest+Serialization.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2017/2/9.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Default

extension SYDownloadRequest {
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched.
    /// - parameter completionHandler: The code to be executed once the request has finished.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func response(_ completionHandler: @escaping (Alamofire.DefaultDownloadResponse) -> Void)
        -> Self {
            self.downloadRequest.validate().response(queue: self.downloadQueue, completionHandler: completionHandler)
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
            self.downloadRequest.validate().response(queue: self.downloadQueue, responseSerializer: responseSerializer, completionHandler: completionHandler)
            return self
    }
}

//MARK: - Data

extension SYDownloadRequest {
    
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
        self.downloadRequest.validate().responseData(queue: self.downloadQueue, completionHandler: completionHandler)
        return self
    }
    
}


//MARK: - String

extension SYDownloadRequest {
    
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
        self.downloadRequest.validate().responseString(queue: self.downloadQueue, encoding: self.downloadStringEncoding, completionHandler: completionHandler)
        return self
    }
}


//MARK: - JSON

extension SYDownloadRequest {
    
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
        self.downloadRequest.validate().responseJSON(queue: self.downloadQueue, options: self.downloadJSONOptions, completionHandler: completionHandler)
        return self
    }
}


//MARK: - PropertyList

extension SYDownloadRequest {
    
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
        self.downloadRequest.validate().responsePropertyList(queue: self.downloadQueue, options: self.downloadPropertyListOptions, completionHandler: completionHandler)
        return self
    }
}

