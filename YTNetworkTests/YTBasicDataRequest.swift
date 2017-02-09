//
//  YTBasicDataRequest.swift
//  YTNetworkExample
//
//  Created by Shannon Yang on 2016/12/29.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import UIKit
import YTNetwork
import Alamofire
import ObjectMapper
import SwiftyJSON

class YTBasicDataRequest: YTDataRequest {
    
    let requestUrlString: String
    let method: HTTPMethod
    let parameters: [String : Any]?
    let keyPath: String?
    
    init(requestUrlString: String, method: HTTPMethod = .post, parameters: [String : Any]? = nil, keyPath: String? = nil) {
        self.requestUrlString = requestUrlString
        self.method = method
        self.parameters = parameters
        self.keyPath = keyPath
        super.init()
    }
    
    override var requestUrl: String {
        return self.requestUrlString
    }
    
    override var requestMethod: HTTPMethod {
        return self.method
    }
    
    override var requestParameters: [String : Any]? {
        return self.parameters
    }
    
    // test object mapper
    override var responseObjectKeyPath: String? {
        guard let keyPath = self.keyPath else {
            return nil
        }
        return keyPath
    }
    
    override var cacheTimeInSeconds: Int {
       return 1000
    }
}
