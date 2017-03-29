//
//  SYDataRequest.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/9.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

open class SYDataRequest: SYRequest {
    
    // MARK: Properties
    
    /// The request sent or to be sent to the server.
    
    open override var request: URLRequest? {
        return self.dataRequest.request
    }
    
    /// The progress of fetching the response data from the server for the request.
    
    open var progress: Progress {
        return self.dataRequest.progress
    }
    
    
    // MARK: Stream
    
    /// Sets a closure to be called periodically during the lifecycle of the request as data is read from the server.
    ///
    /// This closure returns the bytes most recently received from the server, not including data from previous calls.
    /// If this closure is set, data will only be available within this closure, and will not be saved elsewhere. It is
    /// also important to note that the server data in any `Response` object will be `nil`.
    ///
    /// - parameter closure: The code to be executed periodically during the lifecycle of the request.
    ///
    /// - returns: The request.
    
    @discardableResult
    open func stream(closure: ((Data) -> Void)? = nil) -> Self {
        self.dataRequest.stream(closure: closure)
        return self
    }
    
    
    // MARK: Progress
    
    /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is read from the server.
    ///
    /// - returns: The request.
    
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping Alamofire.Request.ProgressHandler) -> Self {
        self.dataRequest.downloadProgress(queue: queue, closure: closure)
        return self
    }
    
    //MARK: - SubClass Override
    
    /// The queue on which the completion handler is dispatched. default is main.
    
    open var responseQueue: DispatchQueue? = nil
    
    /// The string encoding. If `nil`, the string encoding will be determined from the server default is String.Encoding.isoLatin1.
    
    open var responseStringEncoding: String.Encoding? = nil
    
    /// The JSON serialization reading options. Defaults to `.allowFragments`.
    
    open var responseJSONOptions: JSONSerialization.ReadingOptions {
        return .allowFragments
    }
    
    /// The property list reading options. Defaults to `[]`.
    
    open var responsePropertyListOptions: PropertyListSerialization.ReadOptions {
        return []
    }
    
    /// The key path where object mapping should be performed
    
    open var responseObjectKeyPath: String? {
        return nil
    }
    
    /// MapContext is available for developers who wish to pass information around during the mapping process.
    
    open var responseObjectContext: ObjectMapper.MapContext? {
        return nil
    }
    
    /// current data request
    
    lazy var dataRequest: Alamofire.DataRequest = { [unowned self] in
        return self.alamofireRequest as! Alamofire.DataRequest
        }()
}


