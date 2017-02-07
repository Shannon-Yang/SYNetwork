//
//  YTCacheMetadata.swift
//  YTNetwork
//
//  Created by Shannon Yang on 2016/12/7.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import ObjectMapper

/// store cached metadata, implement NSSecureCoding protocol

class YTCacheMetadata: NSObject, NSSecureCoding {
    
    /// cache version
    
    var cacheVersion: String
    
    /// current app version
    
    var appVersionString: String
    
    /// cachemetadate create data
    
    var creationDate: Date
    
    /// request response string encoding, when call "responseString"
    
    var responseStringEncoding: String.Encoding
    
    /// request responseJSONOptions, when call "responseSwiftyJSON" or "responseJSON"
    
    var responseJSONOptions: JSONSerialization.ReadingOptions
    
    /// request responsePropertyListOptions, when call "responsePropertyList"
    
    var responsePropertyListOptions: PropertyListSerialization.ReadOptions
    
    /// request responseObjectKeyPath, when call "responseObject" or "responseObjectArray"
    
    var responseObjectKeyPath: String?
    
    /// request responseObjectContext, when call "responseObject" or "responseObjectArray"
    
    var responseObjectContext: MapContext?
    
    /// supportsSecureCoding
    
    static var supportsSecureCoding: Bool {
        return true
    }
    
    /// aDecoder
    
    required init?(coder aDecoder: NSCoder) {
        
        self.cacheVersion = aDecoder.decodeObject(forKey: "cacheVersion") as! String
        self.appVersionString = aDecoder.decodeObject(forKey: "appVersionString") as! String
        self.creationDate = aDecoder.decodeObject(forKey: "creationDate") as! Date
        self.responseStringEncoding = String.Encoding(rawValue: aDecoder.decodeObject(forKey: "responseStringEncoding") as! UInt)
        self.responseJSONOptions = JSONSerialization.ReadingOptions(rawValue: aDecoder.decodeObject(forKey: "responseJSONOptions") as! UInt)
        self.responsePropertyListOptions = PropertyListSerialization.ReadOptions(rawValue: aDecoder.decodeObject(forKey: "responsePropertyListOptions") as! UInt)
        self.responseObjectKeyPath = aDecoder.decodeObject(forKey: "responseObjectKeyPath") as? String
        self.responseObjectContext = aDecoder.decodeObject(forKey: "responseObjectContext") as? MapContext
    }
    
    /// implement encode
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(self.cacheVersion, forKey: "cacheVersion")
        aCoder.encode(self.appVersionString, forKey: "appVersionString")
        aCoder.encode(self.creationDate, forKey: "creationDate")
        aCoder.encode( self.responseStringEncoding.rawValue, forKey: "responseStringEncoding")
        aCoder.encode(self.responseJSONOptions.rawValue, forKey: "responseJSONOptions")
        aCoder.encode(self.responsePropertyListOptions.rawValue, forKey: "responsePropertyListOptions")
        aCoder.encode(self.responseObjectKeyPath, forKey: "responseObjectKeyPath")
        aCoder.encode(self.responseObjectContext, forKey: "responseObjectContext")
    }
    
    /// default value
    
    override init() {
        self.cacheVersion = ""
        self.appVersionString = ""
        self.creationDate = Date()
        self.responsePropertyListOptions = []
        self.responseStringEncoding = .isoLatin1
        self.responseJSONOptions = .allowFragments
        super.init()
    }
    
}


