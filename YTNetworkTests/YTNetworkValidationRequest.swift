//
//  YTNetworkValidationRequest.swift
//  YTNetworkExample
//
//  Created by Shannon Yang on 2017/2/4.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import UIKit
import YTNetwork
import Alamofire
import SwiftyJSON

class YTNetworkValidationRequest: YTDataRequest {

    let requestUrlString: String
    
    init(requestUrlString: String) {
        self.requestUrlString = requestUrlString
        super.init()
    }
    
    override var requestUrl: String {
        return self.requestUrlString
    }
    
    override var requestMethod: HTTPMethod {
        return .get
    }
}
