//
//  SYDownloadRequest.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/9.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

open class SYDownloadRequest: SYRequest {
    
    //MARK: - SubClass Override
    
    /// The queue on which the completion handler is dispatched. default is nil.
    
    open var downloadQueue: DispatchQueue = .main
    
    /// The final destination URL of the data returned from the server if it was moved.
    
    open var destination: DownloadRequest.Destination? {
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
    
    /// current data request
    
    public var request: DownloadRequest?
    
    public override init() {
        super.init()
        self.request = self.session.download(self.urlString,
                                             method: self.method,
                                             parameters: self.parameters,
                                             encoding: self.encoding,
                                             headers: self.headers,
                                             interceptor: self.interceptor,
                                             requestModifier: self.requestModifier,to: self.destination)
        
    }
    
}
