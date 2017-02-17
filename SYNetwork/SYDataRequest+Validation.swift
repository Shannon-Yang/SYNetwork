//
//  SYDataRequest+Validation.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2016/12/11.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

extension SYDataRequest {
    
    /// Validates the request, using the specified closure.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - parameter validation: A closure to validate the request.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func validate(_ validation: @escaping Alamofire.DataRequest.Validation) -> Self {
        self.dataRequest.validate(validation)
        return self
    }
    
    /// Validates that the response has a status code in the specified sequence.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - parameter range: The range of acceptable status codes.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func validate<S: Sequence>(statusCode acceptableStatusCodes: S) -> Self where S.Iterator.Element == Int {
        self.dataRequest.validate(statusCode: acceptableStatusCodes)
        return self
    }
    
    /// Validates that the response has a content type in the specified sequence.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - parameter contentType: The acceptable content types, which may specify wildcard types and/or subtypes.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func validate<S: Sequence>(contentType acceptableContentTypes: S) -> Self where S.Iterator.Element == String {
        self.dataRequest.validate(contentType: acceptableContentTypes)
        return self
    }
    
    /// Validates that the response has a status code in the default acceptable range of 200...299, and that the content
    /// type matches any specified in the Accept HTTP header field.
    ///
    /// If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - returns: The request.
    
    @discardableResult
    public func validate() -> Self {
        self.dataRequest.validate()
        return self
    }
}

