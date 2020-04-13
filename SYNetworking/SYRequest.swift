//
//  SYRequest.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2016/11/22.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

/// Responsible for sending a request and receiving the response and associated data from the server.

open class SYRequest: NSObject {
    
    //MARK: - Session Config
    
    /// The configuration used to construct the managed session.`URLSessionConfiguration.default` by default
    
    public var configuration: URLSessionConfiguration = URLSessionConfiguration.default
    
    // Underlying `URLSession` for this instance. Default is "URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)"
    
    public var urlSession: URLSession?
    
    /// The delegate used when initializing the session. `SYSessionDelegate()` by default.
    
    public var delegate: SessionDelegate = SessionDelegate()
    
    /// Root `DispatchQueue` for all internal callbacks and state updates. **MUST** be a serial queue. `DispatchQueue(label: "org.alamofire.session.rootQueue")` by default.
    
    public var rootQueue: DispatchQueue = DispatchQueue(label: "org.alamofire.session.rootQueue")
    
    /// Determines whether this instance will automatically start all `Request`s. `true` by default. If set to `false`, all `Request`s created must have `.resume()` called. on them for them to start.
    
    public var startRequestsImmediately: Bool = true
    
    /// `DispatchQueue` on which to perform `URLRequest` creation. By default this queue will use the `rootQueue` as its `target`. A separate queue can be used if it's determined request creation is a bottleneck, but that should only be done after careful testing and profiling. `nil` by default.
    
    public var requestQueue: DispatchQueue? = nil
    
    // `DispatchQueue` on which to perform all response serialization. By default this queue will use the `rootQueue` as its `target`. A separate queue can be used if it's determined response serialization is a bottleneck, but that should only be done after careful testing and profiling. `nil` by default.
    
    public var serializationQueue: DispatchQueue? = nil
    
    //  `RequestInterceptor` to be used for all `Request`s created by this instance. `nil` by default.
    
    public var interceptor: RequestInterceptor? = nil
    
    
    // Closure which provides a `URLRequest` for mutation.
    
    public var requestModifier: ((inout URLRequest) throws -> Void)? = nil
    
    /// he server trust policy manager to use for evaluating all server trust. default is nil
    
    public var serverTrustManager: ServerTrustManager? = nil
    
    // `RedirectHandler` to be used by all `Request`s created by this instance. `nil` by default.
    
    public var redirectHandler: RedirectHandler? = nil
    
    //  - cachedResponseHandler:    `CachedResponseHandler` to be used by all `Request`s created by this instance. `nil` by default.
    
    public var cachedResponseHandler: CachedResponseHandler? = nil
    
    //   - eventMonitors: Additional `EventMonitor`s used by the instance. Alamofire always adds a `AlamofireNotifications` `EventMonitor` to the array passed here. `[]` by default.
    
    public var eventMonitors: [EventMonitor] = []
    
    
    // MARK: Properties
    
    /// cacheMetadata used request's cache
    
    var cacheMetadata: SYCacheMetadata?
    
    
    //MARK: - SubClass Override
    
    /// The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseUrlString`.
    
    open var requestURLString: String {
        return ""
    }
    
    /// Should use CDN when sending request. default is false
    
    open var useCDN: Bool {
        return false
    }
    
    ///  Request base URL, Default is empty string.
    
    open var baseURLString: String {
        return ""
    }
    
    /// Request CDN URL. Default is empty string.
    
    open var cdnURLString: String {
        return ""
    }
    
    /// HTTP request method. default is .post
    
    open var method: HTTPMethod {
        return .post
    }
    
    /// Additional request parameters.
    
    open var parameters: Parameters? {
        return nil
    }
    
    /// Http Header
    
    open var headers: HTTPHeaders? {
        return nil
    }
    
    /// to be used to encode the `parameters` value into the `URLRequest`.
    
    open var encoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    /// The max time duration that cache can stay in disk until it's considered expired. Default is 0, which means response is not actually saved as cache.
    
    open var cacheTimeInSeconds: Int {
        return 0
    }
    
    /// cacheKey can be used to identify and invalidate local cache, default is empty
    
    open var cacheKey: String {
        return ""
    }
    
    /// cacheFileName can be used to custom cache file name, default is empty
    
    open var cacheFileName: String {
        return ""
    }
    
    /// Associates an HTTP Basic credential with the request, The user.
    
    open var username: String {
        return ""
    }
    
    /// Associates an HTTP Basic credential with the request, The password.
    
    open var password: String {
        return ""
    }
    
    /// Associates an HTTP Basic credential with the request, The URL credential persistence. `.ForSession` by default.
    
    open var persistence: URLCredential.Persistence {
        return .forSession
    }
    
    ///  Called on the main thread after request succeeded.
    
    open func requestCompleteFilter<T: ResponseDescription>(_ response: T) { }
    
    ///  Called on the main thread when request failed.
    
    open func requestFailedFilter<T: ResponseDescription>(_ response: T) { }
    
    /// Validate response when request success
    
    open func validateResponseWhenRequestSuccess<T>(_ response: T) -> (Bool, Error?) { return (true, nil) }
    

    //MARK: - Init
    
    // Underlying `URLSession` for this instance.
    
    let session: Session
    
    // init instance
    
    public override init() {
        if let urlSession = self.urlSession {
            self.session = Session(session: urlSession,
                                   delegate: self.delegate,
                                   rootQueue: self.rootQueue,
                                   startRequestsImmediately: self.startRequestsImmediately,
                                   requestQueue: self.requestQueue,
                                   serializationQueue: self.serializationQueue,
                                   interceptor: self.interceptor,
                                   serverTrustManager: self.serverTrustManager,
                                   redirectHandler: self.redirectHandler,
                                   cachedResponseHandler: self.cachedResponseHandler,
                                   eventMonitors: self.eventMonitors)
        } else {
            self.session = Session(configuration: self.configuration, delegate: self.delegate, rootQueue: self.rootQueue, startRequestsImmediately: self.startRequestsImmediately, requestQueue: self.requestQueue, serializationQueue: self.serializationQueue, interceptor: self.interceptor, serverTrustManager: self.serverTrustManager, redirectHandler: self.redirectHandler, cachedResponseHandler: self.cachedResponseHandler, eventMonitors: self.eventMonitors)
        }
        super.init()
    }
}

// MARK: - Private SYRequest

extension SYRequest {
    
    var urlString: String {
        var baseURL = SYNetworkingConfig.sharedInstance.baseURLString
        if self.useCDN {
            if self.cdnURLString.isEmpty {
                baseURL = SYNetworkingConfig.sharedInstance.cdnURLString
            } else {
                baseURL = self.cdnURLString
            }
        } else {
            if !self.baseURLString.isEmpty {
                baseURL = self.baseURLString
            }
        }
        return "\(baseURL)\(self.requestURLString)"
    }
}

//MARK: - Dictionary

extension Dictionary {
    
    mutating func merge(with dictionary: Dictionary?) {
        dictionary?.forEach { updateValue($1, forKey: $0) }
    }
    
    func merged(with dictionary: Dictionary?) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}






