//
//  SYResponse+DescriptionFormat.swift
//  SYNetworking
//
//  Created by Shannon Yang on 2017/2/15.
//  Copyright © 2017年 Shannon Yang. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public struct ResponseCommon {
    
    public var request: URLRequest?
    
    public var response: HTTPURLResponse?
    
    public var timeline: Timeline
    
    public var error: Error?
}

public protocol ResponseDescription {
    
    var responseCommon: ResponseCommon? { get }
    
    func responseDescriptionFormat(_ request: SYRequest) -> String
}

//MARK: - DefaultDataResponse

extension Alamofire.DefaultDataResponse: ResponseDescription {
    
    public func responseDescriptionFormat(_ request: SYRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, data: self.data, error: self.error, timeline: self.timeline)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, timeline: self.timeline, error: self.error)
    }
}

//MARK: - DataResponse

extension Alamofire.DataResponse: ResponseDescription {
    
    public func responseDescriptionFormat(_ request: SYRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, data: self.data, result: self.result.description, error: self.error, timeline: self.timeline)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, timeline: self.timeline, error: self.error)
    }
}

//MARK: - DefaultDownloadResponse

extension Alamofire.DefaultDownloadResponse: ResponseDescription {
    
    public func responseDescriptionFormat(_ request: SYRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, temporaryURL: self.temporaryURL, destinationURL: self.destinationURL, resumeData: self.resumeData, error: self.error, timeline: self.timeline)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, timeline: self.timeline, error: self.error)
    }
}

//MARK: - DownloadResponse

extension Alamofire.DownloadResponse: ResponseDescription {
    
    public func responseDescriptionFormat(_ request: SYRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, temporaryURL: self.temporaryURL, destinationURL: self.destinationURL, resumeData: self.resumeData, result: self.result.description, error: self.error, timeline: self.timeline)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, timeline: self.timeline, error: self.error)
    }
}

func generateResponseDescription(_ request: SYRequest, urlRequest: URLRequest?, response: HTTPURLResponse?, temporaryURL: URL? = nil, destinationURL: URL? = nil, resumeData: Data? = nil, data: Data? = nil, result: String? = nil, error: Error?, timeline: Timeline) -> String {
    
    var mark = "✅😊"
    
    var description = "\n\(mark)"
    
    description.append("  RequestMethod: \(urlRequest?.httpMethod ?? "")  RequestURL: \(urlRequest?.description ?? "")")
    
    let parameters = SYNetworkingConfig.sharedInstance.uniformParameters?.merged(with: request.requestParameters) ?? request.requestParameters
    
    var parametersString = ""
    if let string = JSON(parameters ?? [:]).rawString() {
        parametersString = string
    }
    description.append(" \n↑↑↑↑ [REQUEST]: \n\(parametersString)")
    
    description.append(" \n↓↓↓↓ [RESPONSE]: \n")
    
    if let temporaryURL = temporaryURL {
        description.append("\nTemporaryURL: \(temporaryURL.absoluteString)")
    }
    
    if let destinationURL = destinationURL {
        description.append("\nDestinationURL: \(destinationURL.absoluteString)")
    }
    
    if let resumeData = resumeData {
        description.append("\nResumeData: \(resumeData.count) bytes")
    }
    
    if let error = error {
        mark = "❌😟"
        description.append(" Timeline⏰⏰: \n\(JSON(timeline.debugDescription.replacingOccurrences(of: ",", with: "\n")).description)\nError❗️: \(error.localizedDescription)")
        return description
    }
    
    description.append("\nData: \(data?.count ?? 0) bytes\nResult: \(result ?? "")\nTimeline⏰⏰: \(JSON(timeline.debugDescription.replacingOccurrences(of: ",", with: "\n")).description)")
    
    return description
}

