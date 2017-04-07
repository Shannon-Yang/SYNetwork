//
//  SYDataRequest+Cache.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2016/11/28.
//  Copyright © 2016年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import Alamofire

/// cache load error type

public enum LoadCacheError: Error {
    
    /// does not match the cache key
    
    case cacheKeyMismatch
    
    /// cache Time Expired
    
    case expiredCacheTime
    
    /// cache Time invalid
    
    case invalidCacheTime
    
    /// cached data is invalid
    
    case invalidCacheData
    
    /// Invalid metadata cache
    
    case invalidMetadata
    
    /// invalid request
    
    case invalidRequest
}

/// can do a cache plugin for SYDataRequest

extension SYDataRequest {
    
    /// Update the local cache of the current request, If the cache exists, it overwrites the existing cache,You can go to update existing cache by this method,
    ///
    /// This method will only cacheTimeInSeconds set to greater than 0 to store success,otherwise fails
    ///
    /// - Parameter data: Need to cache data,If optionalData is nil, do not store operation
    
    func cacheToFile(_ responseData: Data?) {
        
        guard self.cacheTimeInSeconds > 0 else {
            return
        }
        guard let data = responseData else {
            return
        }
        guard !self.requestUrl.isEmpty else {
            return
        }
        let path = self.cacheFilePath()
        let cacheQueue = DispatchQueue(label: "com.synetwork.cache", attributes: .concurrent)
        cacheQueue.async {
            do {
                // New data will always overwrite old data.
                try data.write(to: URL(fileURLWithPath: path), options: .atomic)
                let metadata = self.configCacheMetadata()
                NSKeyedArchiver.archiveRootObject(metadata, toFile: self.cacheMetadataFilePath().path)
            } catch let error {
                print("write to file failed = \(error)")
            }
        }
    }
    
    
    /// load local cache
    ///
    /// - customLoadCacheInfo: custom request info to load Cache. Default customLoadCacheInfo is nil, will use 'Self' request info
    ///
    /// - Returns: cache data
    /// - completionHandler: load cache completion handle
    
    public func loadLocalCache(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ loadCacheData: () throws -> Data) -> Void) {
        
        if self.requestUrl.isEmpty {
            completionHandler({ throw LoadCacheError.invalidRequest })
            return
        }
        
        // Make sure cache time in valid.
        
        if self.cacheTimeInSeconds == 0 {
            completionHandler({ throw LoadCacheError.invalidCacheTime })
            return
        }
        
        // Try load metadata.
        
        if !self.loadCacheMetadata(customLoadCacheInfo) {
            completionHandler({ throw LoadCacheError.invalidMetadata })
            return
        }
        
        // Check if cache is still valid.
        
        do {
            _ = try self.validateCacheWithError()
        } catch let error {
            completionHandler({ throw error })
            return
        }
        
        // Try load cache.
        
        self.loadCacheData(customLoadCacheInfo, completionHandler: { data in
            guard let cacheData = data else {
                DispatchQueue.main.async {
                    completionHandler({ throw LoadCacheError.invalidCacheData })
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler({ return cacheData })
            }
        })
    }
    
    
    /// Clear local cache for the current request
    
    public func clearLocalCache(completionHandler: @escaping (_ clearCache: () throws -> Void) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let path = self.cacheFilePath()
            do {
                try FileManager.default.removeItem(atPath: path)
                DispatchQueue.main.async {
                    completionHandler({})
                }
            } catch let error {
                DispatchQueue.main.async {
                    print("clear local cache failed, error = \(error)")
                    completionHandler({  throw error })
                }
            }
        }
    }
    
    
    /// Clear all request's local cache
    
    public static func clearAllLocalCache(completionHandler: @escaping (_ clearCache: () throws -> Void) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let pathOfLibrary = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            let path = "\(pathOfLibrary)/\(Key.SYNetworkCache.rawValue)"
            do {
                try FileManager.default.removeItem(atPath: path)
                DispatchQueue.main.async {
                    completionHandler({})
                }
            } catch let error {
                DispatchQueue.main.async {
                    print("clear all local cache failed, error = \(error)")
                    completionHandler({ throw error })
                }
            }
        }
    }
}


//MARK: - Private SYDataRequest

private extension SYDataRequest {
    
    enum Key: String {
        case SYNetworkCache
        case requestMethod
        case baseUrl
        case requestUrl
        case requestParameters
        case cacheKey
    }
    
    func configCacheMetadata() -> SYCacheMetadata {
        let metadata = SYCacheMetadata()
        metadata.cacheKey = self.cacheKey
        metadata.creationDate = Date()
        metadata.responseStringEncoding = self.stringEncodingWithRequest(request: self)
        metadata.responseJSONOptions = self.responseJSONOptions
        metadata.responsePropertyListOptions = self.responsePropertyListOptions
        metadata.responseObjectKeyPath = self.responseObjectKeyPath
        metadata.responseObjectContext = self.responseObjectContext
        return metadata
    }
    
    func cacheFilePath(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) -> String {
        let fileName = self.cacheFileName(customLoadCacheInfo)
        let pathURL = self.cacheBasePath()
        let path = pathURL.appendingPathComponent(fileName).path
        return path
    }
    
    func cacheBasePath() -> URL {
        let pathOfLibrary = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let pathURL = pathOfLibrary.appendingPathComponent(Key.SYNetworkCache.rawValue)
        self.createDirectoryIfNeeded(path: pathURL.path)
        return pathURL
    }
    
    func createBaseDirectoryAtPath(path: String) {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            self.addDoNotBackupAttribute(path: path)
        } catch let error {
            print("create cache directory failed, error = \(error)")
        }
    }
    
    func cacheFileName(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) -> String {
        if self.cacheFileName.isEmpty {
            var requestMethod: Alamofire.HTTPMethod
            var baseUrl: String
            var requestUrl: String
            var requestParameters = [String: Any]()
            var cacheKey: String
            if let customLoadCacheInfo = customLoadCacheInfo {
                if let method = customLoadCacheInfo.requestMethod {
                    requestMethod = method
                } else {
                    requestMethod = self.requestMethod
                }
                if let baseUrlString = customLoadCacheInfo.baseUrlString {
                    baseUrl = baseUrlString
                } else {
                    baseUrl = SYNetworkingConfig.sharedInstance.baseUrlString
                }
                if let requestUrlString = customLoadCacheInfo.requestUrlString {
                    requestUrl = requestUrlString
                } else {
                    requestUrl = self.requestUrl
                }
                if let parameters = customLoadCacheInfo.requestParameters {
                    requestParameters = parameters
                } else {
                    if let arguments = self.requestParameters {
                        requestParameters = arguments
                    }
                }
                if let key = customLoadCacheInfo.cacheKey {
                    cacheKey = key
                } else {
                    cacheKey = self.cacheKey
                }
            } else {
                requestMethod = self.requestMethod
                baseUrl = SYNetworkingConfig.sharedInstance.baseUrlString
                requestUrl = self.requestUrl
                if let arguments = self.requestParameters {
                    requestParameters = arguments
                }
                cacheKey = self.cacheKey
            }
            let requestInfo = "\(Key.requestMethod.rawValue):\(requestMethod.rawValue) \(Key.baseUrl.rawValue):\(baseUrl) \(Key.requestUrl.rawValue):\(requestUrl) \(Key.requestParameters.rawValue):\(requestParameters) \(Key.cacheKey.rawValue):\(cacheKey)"
            return requestInfo.md5()
        }
        
        return self.cacheFileName
    }
    
    func createDirectoryIfNeeded(path: String) {
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            if !isDir.boolValue {
                // file exists and is not a directory
                do {
                    try FileManager.default.removeItem(atPath: path)
                    self.createBaseDirectoryAtPath(path: path)
                } catch let error {
                    print("file remove failed, error = \(error)")
                }
            }
        } else {
            // file does not exist
            self.createBaseDirectoryAtPath(path: path)
        }
    }
    
    func addDoNotBackupAttribute(path: String) {
        let url = NSURL(fileURLWithPath: path)
        do {
            // https://bugs.swift.org/browse/SR-3289
            try url.setResourceValue(NSNumber.init(value: true), forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch let error {
            print("error to set do not backup attribute, error = \(error)")
        }
    }
    
    func cacheMetadataFilePath(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) -> URL {
        let cacheMetadataFileName = "\(self.cacheFileName(customLoadCacheInfo)).metadata"
        let pathURL = self.cacheBasePath().appendingPathComponent(cacheMetadataFileName)
        return pathURL
    }
    
    func loadCacheData(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil, completionHandler: @escaping (_ data: Data?) -> Void) {
        DispatchQueue.global(qos: .default).async {
            let path = self.cacheFilePath(customLoadCacheInfo)
            let url = URL(fileURLWithPath: path)
            completionHandler(try? Data(contentsOf: url))
        }
    }
    
    func loadCacheMetadata(_ customLoadCacheInfo: CustomLoadCacheInfo? = nil) -> Bool {
        let pathURL = self.cacheMetadataFilePath(customLoadCacheInfo)
        if FileManager.default.fileExists(atPath: pathURL.path, isDirectory: nil) {
            if let cacheMetadata = NSKeyedUnarchiver.unarchiveObject(withFile: pathURL.path) as? SYCacheMetadata {
                self.cacheMetadata = cacheMetadata
                return true
            }
        }
        return false
    }
    
    func validateCacheWithError() throws -> Bool {
        
        guard let cacheMetadata = self.cacheMetadata else {
            throw LoadCacheError.invalidMetadata
        }
        
        // Date
        
        let creationDate = cacheMetadata.creationDate
        let duration = -Int(creationDate.timeIntervalSinceNow)
        if duration < 0 || duration > self.cacheTimeInSeconds {
            throw LoadCacheError.expiredCacheTime
        }
        
        // cacheKey
        
        if cacheMetadata.cacheKey != self.cacheKey {
            throw LoadCacheError.cacheKeyMismatch
        }
        return true
    }
    
    func stringEncodingWithRequest(request: SYRequest) -> String.Encoding {
        var convertedEncoding = String.Encoding.isoLatin1
        if let encodingName = request.response?.textEncodingName as CFString! {
            convertedEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringConvertIANACharSetNameToEncoding(encodingName))
            )
        }
        return convertedEncoding
    }
}
