//
//  Request.swift
//  YTNetwork
//
//  Created by Shannon Yang on 2016/11/22.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

/// Responsible for sending a request and receiving the response and associated data from the server.

open class YTRequest: NSObject {
    
    // MARK: Properties
    
    /// cacheMetadata used request's cache
    
    var cacheMetadata: YTCacheMetadata?
    
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
    
    /// current Request
    
    var alamofireRequest: Alamofire.Request {
        return self.configAlamofireRequest()
    }
}

//MARK: - CustomStringConvertible

extension YTRequest {
    
    /// The textual representation used when written to an output stream, which includes the HTTP method and URL, as
    /// well as the response status code if a response has been received.
    
    open override var description: String {
        return self.alamofireRequest.description
    }
}

//MARK: - CustomDebugStringConvertible

extension YTRequest {
    
    /// The textual representation used when written to an output stream, in the form of a cURL command.
    
    open override var debugDescription: String {
        return self.alamofireRequest.debugDescription
    }
}


// MARK: - Private YTRequest

private extension YTRequest {
    
    var urlString: String {
        
        var baseUrl = YTNetworkConfig.sharedInstance.baseUrlString
        if self.useCDN {
            if self.cdnUrl.isEmpty {
                baseUrl = YTNetworkConfig.sharedInstance.cdnUrlString
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
    
    func configAlamofireRequest() -> Alamofire.Request {
        return YTSessionManager.sharedInstance.request(self.urlString, method: self.requestMethod, parameters: self.requestParameters, encoding: self.encoding, headers: self.headers)
    }
}


//MARK: - YTDataRequest

open class YTDataRequest: YTRequest {
    
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
    
    /// The queue on which the completion handler is dispatched. default is nil.
    
    open var responseQueue: DispatchQueue? = nil
    
    /// The string encoding. If `nil`, the string encoding will be determined from the server default is nil.
    
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

//MARK: - YTDownloadRequest

open class YTDownloadRequest: YTRequest {
    
    // MARK: Properties
    
    /// The request sent or to be sent to the server.
    
    open override var request: URLRequest? {
        return self.downloadRequest.request
    }
    
    /// The resume data of the underlying download task if available after a failure.
    
    var resumeData: Data? {
        return self.downloadRequest.resumeData
    }
    
    /// The progress of downloading the response data from the server for the request.
    
    open var progress: Progress {
        return self.downloadRequest.progress
    }
    
    // MARK: State
    
    /// Cancels the request.
    
    open override func cancel() {
        self.downloadRequest.cancel()
    }
    
    // MARK: Progress
    
    /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is read from the server.
    ///
    /// - returns: The request.
    
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping Alamofire.DownloadRequest.ProgressHandler) -> Self {
        self.downloadRequest.downloadProgress(queue: queue, closure: closure)
        return self
    }
    
    // MARK: Destination
    
    /// Creates a download file destination closure which uses the default file manager to move the temporary file to a
    /// file URL in the first available directory with the specified search path directory and search path domain mask.
    ///
    /// - parameter directory: The search path directory. `.DocumentDirectory` by default.
    /// - parameter domain:    The search path domain mask. `.UserDomainMask` by default.
    ///
    /// - returns: A download file destination closure.
    
    open class func suggestedDownloadDestination(
        for directory: FileManager.SearchPathDirectory = .documentDirectory,
        in domain: FileManager.SearchPathDomainMask = .userDomainMask)
        -> Alamofire.DownloadRequest.DownloadFileDestination {
            return Alamofire.DownloadRequest.suggestedDownloadDestination(for: directory, in: domain)
    }
    
    //MARK: - SubClass Override
    
    /// The queue on which the completion handler is dispatched. default is nil.
    
    open var downloadQueue: DispatchQueue? {
        return nil
    }
    
    /// The final destination URL of the data returned from the server if it was moved.
    
    open var destination: Alamofire.DownloadRequest.DownloadFileDestination? {
        return nil
    }
    
    ///  The string encoding. If `nil`, the string encoding will be determined from the
    ///                                server response, falling back to the default HTTP default character set,
    ///                                ISO-8859-1.
    
    open var downloadStringEncoding: String.Encoding? {
        return nil
    }
    
    /// The JSON serialization reading options. Defaults to `.allowFragments`.
    
    open var downloadJSONOptions: JSONSerialization.ReadingOptions {
        return .allowFragments
    }
    
    /// The property list reading options. Defaults to `[]`.
    
    open var downloadPropertyListOptions: PropertyListSerialization.ReadOptions {
        return []
    }
    
    /// override current alamofireRequest
    
    override var alamofireRequest: Alamofire.Request {
        return self.configDownloadRequest()
    }
    
    /// current downloadRequest
    
    lazy var downloadRequest: Alamofire.DownloadRequest = { [unowned self] in
        return self.alamofireRequest as! Alamofire.DownloadRequest
        }()
}

//MARK: - Private YTDownloadRequest

private extension YTDownloadRequest {
    
    func configDownloadRequest() -> Alamofire.DownloadRequest {
        let downloadRequest = YTSessionManager.sharedInstance.download(self.urlString, method: self.requestMethod, parameters: self.requestParameters, encoding: self.encoding, headers: self.headers, to: self.destination)
        if let resumeData = downloadRequest.resumeData {
            return YTSessionManager.sharedInstance.download(resumingWith: resumeData, to: self.destination)
        }
        return downloadRequest
    }
}


//MARK: - YTUploadRequest

open class YTUploadRequest: YTDataRequest {
    
    /// upload type
    
    public enum UploadType {
        
        /// file type, URL must be valid
        
        case file(URL)
        
        /// data type, data must be valid
        
        case data(Data)
        
        /// inputStream, inputStream must be valid
        
        case inputStream(InputStream)
    }
    
    // MARK: Properties
    
    /// The request sent or to be sent to the server.
    
    open override var request: URLRequest? {
        return self.dataRequest.request
    }
    
    /// The progress of uploading the payload to the server for the upload request.
    
    open var uploadProgress: Progress {
        return self.uploadRequest.uploadProgress
    }
    
    // MARK: Upload Progress
    
    /// Sets a closure to be called periodically during the lifecycle of the `UploadRequest` as data is sent to
    /// the server.
    ///
    /// After the data is sent to the server, the `progress(queue:closure:)` APIs can be used to monitor the progress
    /// of data being read from the server.
    ///
    /// - parameter queue:   The dispatch queue to execute the closure on.
    /// - parameter closure: The code to be executed periodically as data is sent to the server.
    ///
    /// - returns: The request.
    
    @discardableResult
    open func uploadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping Alamofire.Request.ProgressHandler) -> Self {
        self.uploadRequest.uploadProgress(queue: queue, closure: closure)
        return self
    }
    
    //MARK: - SubClass Override
    
    /// The encoding memory threshold in bytes.
    
    open var encodingMemoryThreshold: UInt64 {
        return Alamofire.SessionManager.multipartFormDataEncodingMemoryThreshold
    }
    
    /// The closure used to append body parts to the `MultipartFormData`.
    
    open var uploadMultipartFormData: ((MultipartFormData) -> Void)? {
        return nil
    }
    
    /// upload type, default is empty data, In the subclass must return a correct value, otherwise it will fail
    
    open var uploadType: UploadType {
        return .data(Data())
    }
    
    /// override current alamofireRequest
    
    override var alamofireRequest: Alamofire.Request {
        return self.configUploadRequest()
    }
    
    /// current uploadRequest
    
    lazy var uploadRequest: Alamofire.UploadRequest = { [unowned self] in
        return self.alamofireRequest as! Alamofire.UploadRequest
        }()
}

//MARK: - MultipartFormData

extension YTUploadRequest {
    
    public func uploadMultipartFormData(_ encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?) {
        guard let uploadMultipartFormData = self.uploadMultipartFormData else {
            print("uploadMultipartFormData is nil")
            return
        }
        YTSessionManager.sharedInstance.upload(multipartFormData: uploadMultipartFormData, usingThreshold: self.encodingMemoryThreshold, to: self.urlString, method: self.requestMethod, headers: self.headers, encodingCompletion: encodingCompletion)
    }
}

//MARK: - Private YTUploadRequest

private extension YTUploadRequest {
    
    func configUploadRequest() -> Alamofire.UploadRequest {
        switch self.uploadType {
        case .file(let url):
            return YTSessionManager.sharedInstance.upload(url, to: self.urlString, method: self.requestMethod, headers: self.headers)
        case .data(let data):
            if data.count == 0 {
                print("uploadType is nil, In the subclass must return a correct value, otherwise it will fail")
            }
            return YTSessionManager.sharedInstance.upload(data, to: self.urlString, method: self.requestMethod, headers: self.headers)
        case .inputStream(let inputStream):
            return YTSessionManager.sharedInstance.upload(inputStream, to: self.urlString, method: self.requestMethod, headers: self.headers)
        }
    }
}

//MARK: - YTStreamRequest

open class YTStreamRequest: YTRequest {
    
    //MARK: - Properties
    
    /// The hostname of the server to connect to.
    
    var hostName: String {
        return ""
    }
    
    /// The port of the server to connect to.
    
    var port: Int {
        return 0
    }
    
    /// The net service used to identify the endpoint.
    
    var netService: NetService? {
        return nil
    }
    
    /// override current alamofireRequest
    
    override var alamofireRequest: Request {
        if #available(iOS 9.0, *) {
            return self.configStreamRequest()
        }
        return super.alamofireRequest
    }
}

//MARK: - Private YTStreamRequest

private extension YTStreamRequest {
    
    @available(iOS 9.0, *)
    func configStreamRequest() -> Alamofire.StreamRequest {
        if let netService = self.netService {
            return YTSessionManager.sharedInstance.stream(with: netService)
        } else {
            return YTSessionManager.sharedInstance.stream(withHostName: self.hostName, port: self.port)
        }
    }
}




