//
//  YTSessionManager.swift
//  YTNetwork
//
//  Created by Shannon Yang on 2017/1/24.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

/// Responsible for creating and managing `Request` objects,Inherited from Alamofire.SessionManager, as well as their underlying `NSURLSession`.

public class YTSessionManager: Alamofire.SessionManager {
    
    /// A instance of `YTSessionManager`, used by top-level Alamofire request methods, and suitable for use
    /// directly for any ad hoc requests.
    
    public static let sharedInstance : YTSessionManager = {
        
        guard YTNetworkConfig.sharedInstance.configuration == URLSessionConfiguration.default else {
            return YTSessionManager(configuration: YTNetworkConfig.sharedInstance.configuration, delegate: YTNetworkConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: YTNetworkConfig.sharedInstance.serverTrustPolicyManager)
        }
        
        guard let headers = YTNetworkConfig.sharedInstance.configuration.httpAdditionalHeaders else {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = YTSessionManager.defaultHTTPHeaders
            return YTSessionManager(configuration: configuration, delegate: YTNetworkConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: YTNetworkConfig.sharedInstance.serverTrustPolicyManager)
        }
        
        return YTSessionManager(configuration: YTNetworkConfig.sharedInstance.configuration, delegate: YTNetworkConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: YTNetworkConfig.sharedInstance.serverTrustPolicyManager)
    }()
}

