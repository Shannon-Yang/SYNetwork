//
//  SYNetworkingDownloadRequest.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/4.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import UIKit
import SYNetworking
import Alamofire
import SwiftyJSON

class SYNetworkingDownloadRequest: SYDownloadRequest {
    
    let requestUrlString: String
    let method: HTTPMethod
    let header: [String : String]?
    let destinationPath: DownloadRequest.DownloadFileDestination?
    let parameters: [String : Any]?
    
    init(requestUrlString: String,method: HTTPMethod = .get, header: [String : String]? = nil, destinationPath: DownloadRequest.DownloadFileDestination? = nil, parameters: [String : Any]? = nil) {
        self.requestUrlString = requestUrlString
        self.method = method
        self.header = header
        self.destinationPath = destinationPath
        self.parameters = parameters
        super.init()
    }
    
    override var requestParameters: [String : Any]? {
        return self.parameters
    }
    
    override var requestURLString: String {
        return self.requestUrlString
    }
    
    override var requestMethod: HTTPMethod {
        return self.method
    }
    
    override var headers: [String : String]? {
        return self.header
    }
    
    override var destination: DownloadRequest.DownloadFileDestination? {
        return self.destinationPath
    }
}




