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
    
    //MARK: - SubClass Override
    
    /// The queue on which the completion handler is dispatched. default is main.
    
    open var responseQueue: DispatchQueue = .main
    
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
    
    open var request: DataRequest?
    
    public override init() {
        super.init()
        self.request = self.session.request(self.urlString,
                                            method: self.method,
                                            parameters: self.parameters,
                                            encoding: self.encoding,
                                            headers: self.headers,
                                            interceptor: self.interceptor,
                                            requestModifier: self.requestModifier)
    }
}


