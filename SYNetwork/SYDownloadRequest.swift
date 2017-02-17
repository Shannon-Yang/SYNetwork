//
//  SYDownloadRequest.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2017/2/9.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

open class SYDownloadRequest: SYRequest {
    
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

//MARK: - Private SYDownloadRequest

private extension SYDownloadRequest {
    
    func configDownloadRequest() -> Alamofire.DownloadRequest {
        let downloadRequest = SYSessionManager.sharedInstance.download(self.urlString, method: self.requestMethod, parameters: self.requestParameters, encoding: self.encoding, headers: self.headers, to: self.destination)
        if let resumeData = downloadRequest.resumeData {
            return SYSessionManager.sharedInstance.download(resumingWith: resumeData, to: self.destination)
        }
        return downloadRequest
    }
}
