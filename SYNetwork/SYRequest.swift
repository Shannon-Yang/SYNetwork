//
//  SYRequest.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2016/11/22.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

/// Responsible for sending a request and receiving the response and associated data from the server.

open class SYRequest: NSObject {
    
    // MARK: Properties
    
    /// cacheMetadata used request's cache
    
    var cacheMetadata: SYCacheMetadata?
    
    /// The delegate for the underlying task.
    
    open var delegate: TaskDelegate {
        return self.alamofireRequest.delegate
    }
    
    /// The underlying task.
    
    open var task: URLSessionTask? {
        return self.alamofireRequest.task
    }
    
    /// The request sent or to be sent to the server.
    
    open var request: URLRequest? {
        return self.alamofireRequest.request
    }
    
    /// The response received from the server, if any.
    
    open var response: HTTPURLResponse? {
        return self.alamofireRequest.response
    }
    
    /// The number of times the request has been retried.
    
    open var retryCount: UInt {
        return self.alamofireRequest.retryCount
    }
    
    /// The session belonging to the underlying task.
    
    open var session: URLSession {
        return self.alamofireRequest.session
    }
    
    // MARK: Authentication
    
    /// Associates an HTTP Basic credential with the request.
    ///
    /// - returns: The request.
    
    @discardableResult
    open func authenticate() -> Self {
        self.alamofireRequest.authenticate(user: self.user, password: self.password, persistence: self.persistence)
        return self
    }
    
    // MARK: State
    
    /// Resumes the request.
    
    open func resume() {
        self.alamofireRequest.resume()
    }
    
    /// Suspends the request.
    
    open func suspend() {
        self.alamofireRequest.suspend()
    }
    
    /// Cancels the request.
    
    open func cancel() {
        self.alamofireRequest.cancel()
    }
    
    
    //MARK: - SubClass Override
    
    /// The URL path of request. This should only contain the path part of URL, e.g., /v1/user. See alse `baseUrl`.
    
    open var requestUrl: String {
        return ""
    }
    
    /// Should use CDN when sending request. default is false
    
    open var useCDN: Bool {
        return false
    }
    
    ///  Request base URL, Default is empty string.
    
    open var baseUrl: String {
        return ""
    }
    
    /// Request CDN URL. Default is empty string.
    
    open var cdnUrl: String {
        return ""
    }
    
    /// HTTP request method. default is .post
    
    open var requestMethod: Alamofire.HTTPMethod {
        return .post
    }
    
    /// Additional request parameters.
    
    open var requestParameters: [String: Any]? {
        return nil
    }
    
    /// Http Header
    
    open var headers: [String: String]? {
        return nil
    }
    
    /// An encoding mode used http request. default is URLEncoding.default
    
    open var encoding: Alamofire.ParameterEncoding {
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
    
    /// Associates an HTTP Basic credential with the request, The user.
    
    open var user: String {
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
    
    open func requestCompleteFilter<T: ResponseDescriptionFormatting>(_ response: T) { }
    
    ///  Called on the main thread when request failed.
    
    open func requestFailedFilter<T: ResponseDescriptionFormatting>(_ response: T) { }
    
    /// Validate Response
    
    open func validateResponse<T: ResponseDescriptionFormatting>(_ response: T) -> Bool { return true }
    
    /// current Request
    
    var alamofireRequest: Alamofire.Request {
        return self.setupAlamofireRequest()
    }
}

//MARK: - CustomStringConvertible

extension SYRequest {
    
    /// The textual representation used when written to an output stream, which includes the HTTP method and URL, as
    /// well as the response status code if a response has been received.
    
    open override var description: String {
        return self.alamofireRequest.description
    }
}

//MARK: - CustomDebugStringConvertible

extension SYRequest {
    
    /// The textual representation used when written to an output stream, in the form of a cURL command.
    
    open override var debugDescription: String {
        return self.alamofireRequest.debugDescription
    }
}


// MARK: - Private SYRequest

extension SYRequest {
    
    var urlString: String {
        
        var baseUrl = SYNetworkConfig.sharedInstance.baseUrlString
        if self.useCDN {
            if self.cdnUrl.isEmpty {
                baseUrl = SYNetworkConfig.sharedInstance.cdnUrlString
            } else {
                baseUrl = self.cdnUrl
            }
        } else {
            if !self.baseUrl.isEmpty {
                baseUrl = self.baseUrl
            }
        }
        return "\(baseUrl)\(self.requestUrl)"
    }
    
    func setupAlamofireRequest() -> Alamofire.Request {
        return SYSessionManager.sharedInstance.request(self.urlString, method: self.requestMethod, parameters: SYNetworkConfig.sharedInstance.uniformParameters?.merged(with: self.requestParameters) ?? self.requestParameters, encoding: self.encoding, headers: self.headers)
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






