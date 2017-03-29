//
//  SYUploadRequest.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/9.
//  Copyright © 2017年 Shannon Yang. All rights reserved.
//

import Foundation
import Alamofire

open class SYUploadRequest: SYDataRequest {
    
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

extension SYUploadRequest {
    
    public func uploadMultipartFormData(_ encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?) {
        guard let uploadMultipartFormData = self.uploadMultipartFormData else {
            assertionFailure("uploadMultipartFormData is nil")
            return
        }
        SYSessionManager.sharedInstance.upload(multipartFormData: uploadMultipartFormData, usingThreshold: self.encodingMemoryThreshold, to: self.urlString, method: self.requestMethod, headers: self.headers, encodingCompletion: encodingCompletion)
    }
}

//MARK: - Private SYUploadRequest

private extension SYUploadRequest {
    
    func configUploadRequest() -> Alamofire.UploadRequest {
        switch self.uploadType {
        case .file(let url):
            return SYSessionManager.sharedInstance.upload(url, to: self.urlString, method: self.requestMethod, headers: self.headers)
        case .data(let data):
            if data.count == 0 {
                assertionFailure("uploadType is nil, In the subclass must return a correct value, otherwise it will fail")
            }
            return SYSessionManager.sharedInstance.upload(data, to: self.urlString, method: self.requestMethod, headers: self.headers)
        case .inputStream(let inputStream):
            return SYSessionManager.sharedInstance.upload(inputStream, to: self.urlString, method: self.requestMethod, headers: self.headers)
        }
    }
}

