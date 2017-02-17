//
//  SYBasicDataRequest.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2016/12/29.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import UIKit
import SYNetwork
import Alamofire
import ObjectMapper
import SwiftyJSON

class SYBasicDataRequest: SYDataRequest {
    
    let requestUrlString: String
    let method: HTTPMethod
    let parameters: [String : Any]?
    let keyPath: String?
    let cacheTime: Int?
    let key: String?
    
    init(requestUrlString: String, method: HTTPMethod = .post, parameters: [String : Any]? = nil, keyPath: String? = nil, cacheTimeInSeconds: Int? = 1000, cacheKey: String? = nil) {
        self.requestUrlString = requestUrlString
        self.method = method
        self.parameters = parameters
        self.keyPath = keyPath
        self.cacheTime = cacheTimeInSeconds
        self.key = cacheKey
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
    
    override var cacheKey: String {
        guard let key = key else {
            return ""
        }
        return key
    }
    
    // test object mapper
    override var responseObjectKeyPath: String? {
        guard let keyPath = self.keyPath else {
            return nil
        }
        return keyPath
    }
    
    override var cacheTimeInSeconds: Int {
        guard let time = self.cacheTime else {
            return 0
        }
        return time
    }
}
