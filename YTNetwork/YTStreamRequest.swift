//
//  YTStreamRequest.swift
//  YTNetworkExample
//
//  Created by Shannon Yang on 2017/2/9.
//  Copyright © 2017年 Shannon Yang. All rights reserved.
//

import Foundation
import Alamofire

open class YTStreamRequest: YTRequest {
    
    //MARK: - Properties
    
    /// The hostname of the server to connect to.
    
    var hostName: String {
        return ""
    }
    
    /// The port of the server to connect to.
    
    var port: Int {
        return 0
    }
    
    /// The net service used to identify the endpoint.
    
    var netService: NetService? {
        return nil
    }
    
    /// override current alamofireRequest
    
    override var alamofireRequest: Request {
        if #available(iOS 9.0, *) {
            return self.configStreamRequest()
        }
        return super.alamofireRequest
    }
}

//MARK: - Private YTStreamRequest

private extension YTStreamRequest {
    
    @available(iOS 9.0, *)
    func configStreamRequest() -> Alamofire.StreamRequest {
        if let netService = self.netService {
            return YTSessionManager.sharedInstance.stream(with: netService)
        } else {
            return YTSessionManager.sharedInstance.stream(withHostName: self.hostName, port: self.port)
        }
    }
}
