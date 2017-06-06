//
//  SYNetworkingValidationRequest.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/4.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import UIKit
import SYNetworking
import Alamofire
import SwiftyJSON

class SYNetworkingValidationRequest: SYDataRequest {

    let requestUrlString: String
    
    init(requestUrlString: String) {
        self.requestUrlString = requestUrlString
        super.init()
    }
    
    override var requestURLString: String {
        return self.requestUrlString
    }
    
    override var requestMethod: HTTPMethod {
        return .get
    }
}
