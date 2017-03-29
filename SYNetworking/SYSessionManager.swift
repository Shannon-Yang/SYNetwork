//
//  SYSessionManager.swift
//  SYNetworking
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
        
        guard SYNetworkingConfig.sharedInstance.configuration == URLSessionConfiguration.default else {
            return SYSessionManager(configuration: SYNetworkingConfig.sharedInstance.configuration, delegate: SYNetworkingConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: SYNetworkingConfig.sharedInstance.serverTrustPolicyManager)
        }
        
        guard let headers = SYNetworkingConfig.sharedInstance.configuration.httpAdditionalHeaders else {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = SYSessionManager.defaultHTTPHeaders
            return SYSessionManager(configuration: configuration, delegate: SYNetworkingConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: SYNetworkingConfig.sharedInstance.serverTrustPolicyManager)
        }
        
        return SYSessionManager(configuration: SYNetworkingConfig.sharedInstance.configuration, delegate: SYNetworkingConfig.sharedInstance.sessionDelegate, serverTrustPolicyManager: SYNetworkingConfig.sharedInstance.serverTrustPolicyManager)
    }()
}
