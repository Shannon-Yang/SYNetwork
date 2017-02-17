//
//  SYSessionManager.swift
//  SYNetwork
//
//  Created by Shannon Yang on 2017/1/24.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

/// Responsible for creating and managing `Request` objects,Inherited from Alamofire.SessionManager, as well as their underlying `NSURLSession`.

public class SYSessionManager: Alamofire.SessionManager {
    
    /// A instance of `SYSessionManager`, used by top-level Alamofire request methods, and suitable for use
    /// directly for any ad hoc requests.
    
    public static let sharedInstance : SYSessionManager = {
        
        guard SYNetworkConfig.sharedInstance.configuration == URLSessionConfiguration.default else {
            return SYSessionManager(configuration: SYNetworkConfig.sharedInstance.configuration, delegate: SYNetworkConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: SYNetworkConfig.sharedInstance.serverTrustPolicyManager)
        }
        
        guard let headers = SYNetworkConfig.sharedInstance.configuration.httpAdditionalHeaders else {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = SYSessionManager.defaultHTTPHeaders
            return SYSessionManager(configuration: configuration, delegate: SYNetworkConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: SYNetworkConfig.sharedInstance.serverTrustPolicyManager)
        }
        
        return SYSessionManager(configuration: SYNetworkConfig.sharedInstance.configuration, delegate: SYNetworkConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: SYNetworkConfig.sharedInstance.serverTrustPolicyManager)
    }()
}

