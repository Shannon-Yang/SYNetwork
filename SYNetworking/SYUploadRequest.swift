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
        
        /// multipartFormData, multipartFormData must be valid
        
        case multipartFormData(MultipartFormData)
    }
    
    //MARK: - SubClass Override
    
    
    /// `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    
    open var fileManager: FileManager = .default
    
    /// The encoding memory threshold in bytes.
    
    open var encodingMemoryThreshold: UInt64 {
        return MultipartFormData.encodingMemoryThreshold
    }
    
    /// The closure used to append body parts to the `MultipartFormData`.
    
    open var uploadMultipartFormData: ((MultipartFormData) -> Void)? {
        return nil
    }
    
    /// upload type, default is empty data, In the subclass must return a correct value, otherwise it will fail
    
    open var uploadType: UploadType {
        return .data(Data())
    }

    /// current data request
    
    public override init() {
        super.init()
        switch self.uploadType {
        case .data(let data):
            if data.count == 0 {
                assertionFailure("uploadType is nil, In the subclass must return a correct value, otherwise it will fail")
            }
            self.request = self.session.upload(data,
                                               to: self.urlString,
                                               method: self.method,
                                               headers: self.headers,
                                               interceptor: self.interceptor,
                                               fileManager: self.fileManager,
                                               requestModifier: self.requestModifier)
        case .file(let url):
            self.request = self.session.upload(url,
                                               to: self.urlString,
                                               method: self.method,
                                               headers: self.headers,
                                               interceptor: self.interceptor,
                                               fileManager: self.fileManager,
                                               requestModifier: self.requestModifier)
        case .inputStream(let stream):
            self.request = self.session.upload(stream,
                                               to: self.urlString,
                                               method: self.method,
                                               headers: self.headers,
                                               interceptor: self.interceptor,
                                               fileManager: self.fileManager,
                                               requestModifier: self.requestModifier)
        case .multipartFormData(let multipartFormData):
            self.request = self.session.upload(multipartFormData: multipartFormData, to: self.urlString, usingThreshold: self.encodingMemoryThreshold, method: self.method, headers: self.headers, interceptor: self.interceptor, fileManager: self.fileManager, requestModifier: self.requestModifier)
            
        }
        
    }
}

