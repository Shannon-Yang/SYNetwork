//
//  YTResponse+DescriptionFormat.swift
//  YTResponse+DescriptionFormat
//
//  Created by Shannon Yang on 2017/2/15.
//  Copyright © 2017年 Shannon Yang. All rights reserved.
//

import Foundation
import Alamofire

public protocol ResponseDescriptionFormatting {
    
    func responseDescriptionFormat(_ request: YTRequest) -> String
}

//MARK: - DefaultDataResponse

extension Alamofire.DefaultDataResponse: ResponseDescriptionFormatting {
    
    public func responseDescriptionFormat(_ request: YTRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, data: self.data, error: self.error, timeline: self.timeline)
    }
}

//MARK: - DataResponse

extension Alamofire.DataResponse: ResponseDescriptionFormatting {
    
    public func responseDescriptionFormat(_ request: YTRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, data: self.data, result: self.result.description, error: self.error, timeline: self.timeline)
    }
}

//MARK: - DefaultDownloadResponse

extension Alamofire.DefaultDownloadResponse: ResponseDescriptionFormatting {
    
    public func responseDescriptionFormat(_ request: YTRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, temporaryURL: self.temporaryURL, destinationURL: self.destinationURL, resumeData: self.resumeData, error: self.error, timeline: self.timeline)
    }
}

//MARK: - DownloadResponse

extension Alamofire.DownloadResponse: ResponseDescriptionFormatting {
    
    public func responseDescriptionFormat(_ request: YTRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, temporaryURL: self.temporaryURL, destinationURL: self.destinationURL, resumeData: self.resumeData, result: self.result.description, error: self.error, timeline: self.timeline)
    }
}

func generateResponseDescription(_ request: YTRequest, urlRequest: URLRequest?, response: HTTPURLResponse?, temporaryURL: URL? = nil, destinationURL: URL? = nil, resumeData: Data? = nil, data: Data? = nil, result: String? = nil, error: Error?, timeline: Timeline) -> String {
    
    var mark = "✅😊"
    
    var description = "\n\(mark)"
    
    description.append("  \(urlRequest?.httpMethod)  \(urlRequest?.description)")
    
    description.append("⬆️⬆️⬆️ [REQUEST]:\n\(YTNetworkConfig.sharedInstance.uniformParameters?.merged(with: request.requestParameters) ?? request.requestParameters)")
    
    description.append("⬇️⬇️⬇️ [RESPONSE]:\n")
    
    if let temporaryURL = temporaryURL {
        description.append("TemporaryURL: \(temporaryURL.absoluteString)\n")
    }
    
    if let destinationURL = destinationURL {
        description.append("DestinationURL: \(destinationURL.absoluteString)\n")
    }
    
    if let resumeData = resumeData {
        description.append("ResumeData: \(resumeData.count) bytes\n")
    }
    
    if let error = error {
        mark = "❌😟"
        description.append("Timeline⏰: \(timeline.debugDescription.replacingOccurrences(of: ",", with: "\n"))\nError❗️: \(error.localizedDescription)")
        return description
    }
    
    description.append("Data: \(data?.count ?? 0) bytes\nResult: \(result)\nTimeline⏰: \(timeline.debugDescription.replacingOccurrences(of: ",", with: "\n"))")
    
    return description
}

