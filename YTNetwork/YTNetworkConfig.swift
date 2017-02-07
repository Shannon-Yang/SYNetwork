//
//  YTNetworkConfig.swift
//  YTNetwork
//
//  Created by Shannon Yang on 16/8/16.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import ObjectMapper

///  YTNetworkConfig stored global network-related configurations, which will be used in `YTRequest`,as well as caching response.

public class YTNetworkConfig {
    
    /// Return a shared config object.
    
    public static let sharedInstance : YTNetworkConfig = YTNetworkConfig()
    
    ///  Request base URL, Default is empty string.
    
    public var baseUrlString: String = ""
    
    /// Request CDN URL. Default is empty string.
    
    public var cdnUrlString: String = ""

    /// Request Uniform Parameters. Default is empty.
    
    public var uniformParameters: [String: AnyObject] = [:]
    
    /// he server trust policy manager to use for evaluating all server trust. default is nil
    
    public var serverTrustPolicyManager: Alamofire.ServerTrustPolicyManager? = nil
    
    /// The configuration used to construct the managed session.                                `URLSessionConfiguration.default` by default
    
    public var configuration: URLSessionConfiguration = URLSessionConfiguration.default
    
    /// The delegate used when initializing the session. `SessionDelegate()` by default.
    
    public var sessionDelegate: Alamofire.SessionDelegate = Alamofire.SessionDelegate()
}

