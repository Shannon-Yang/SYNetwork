//
//  SYCacheMetadata.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2016/12/7.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import ObjectMapper

/// store cached metadata, implement NSSecureCoding protocol

class SYCacheMetadata: NSObject, NSSecureCoding {
    
    /// can be used to identify and invalidate local cache
    
    var cacheKey: String
    
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
    
    //MARK: - Enum
    
    enum Key: String {
        case cacheKey
        case creationDate
        case responseStringEncoding
        case responseJSONOptions
        case responsePropertyListOptions
        case responseObjectKeyPath
        case responseObjectContext
    }
    
    
    //MARK: - aDecoder
    
    required init?(coder aDecoder: NSCoder) {
        self.cacheKey = aDecoder.decodeObject(forKey: Key.cacheKey.rawValue) as! String
        self.creationDate = aDecoder.decodeObject(forKey: Key.creationDate.rawValue) as! Date
        self.responseStringEncoding = String.Encoding(rawValue: aDecoder.decodeObject(forKey: Key.responseStringEncoding.rawValue) as! UInt)
        self.responseJSONOptions = JSONSerialization.ReadingOptions(rawValue: aDecoder.decodeObject(forKey: Key.responseJSONOptions.rawValue) as! UInt)
        self.responsePropertyListOptions = PropertyListSerialization.ReadOptions(rawValue: aDecoder.decodeObject(forKey: Key.responsePropertyListOptions.rawValue) as! UInt)
        self.responseObjectKeyPath = aDecoder.decodeObject(forKey: Key.responseObjectKeyPath.rawValue) as? String
        self.responseObjectContext = aDecoder.decodeObject(forKey: Key.responseObjectContext.rawValue) as? MapContext
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.cacheKey, forKey: Key.cacheKey.rawValue)
        aCoder.encode(self.creationDate, forKey: Key.creationDate.rawValue)
        aCoder.encode( self.responseStringEncoding.rawValue, forKey: Key.responseStringEncoding.rawValue)
        aCoder.encode(self.responseJSONOptions.rawValue, forKey: Key.responseJSONOptions.rawValue)
        aCoder.encode(self.responsePropertyListOptions.rawValue, forKey: Key.responsePropertyListOptions.rawValue)
        aCoder.encode(self.responseObjectKeyPath, forKey: Key.responseObjectKeyPath.rawValue)
        aCoder.encode(self.responseObjectContext, forKey: Key.responseObjectContext.rawValue)
    }
    
    //MARK: - Init
    
    override init() {
        self.cacheKey = ""
        self.creationDate = Date()
        self.responsePropertyListOptions = []
        self.responseStringEncoding = .isoLatin1
        self.responseJSONOptions = .allowFragments
        super.init()
    }
    
}


