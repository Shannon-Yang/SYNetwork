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
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, data: self.data, error: self.error, timeline: self.timeline)
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
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, temporaryURL: self.temporaryURL, destinationURL: self.destinationURL, resumeData: self.resumeData, error: self.error, timeline: self.timeline)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, timeline: self.timeline, error: self.error)
    }
}

func generateResponseDescription(_ request: SYRequest, urlRequest: URLRequest?, response: HTTPURLResponse?, temporaryURL: URL? = nil, destinationURL: URL? = nil, resumeData: Data? = nil, data: Data? = nil, error: Error?, timeline: Timeline) -> String {
    
    func generateTimelineResponseDescription(timeline: Timeline) -> String {
        let description = "{ \n  Request Start Time: \(timeline.requestStartTime)\n\n  Initial Response Time: \(timeline.initialResponseTime)\n\n  Request Completed Time: \(timeline.requestCompletedTime)\n\n  Serialization Completed Time: \(timeline.serializationCompletedTime)\n\n  Latency: \(timeline.latency) secs\n\n  Request Duration: \(timeline.requestDuration) secs\n\n  Serialization Duration: \(timeline.serializationDuration) secs\n\n  Total Duration: \(timeline.totalDuration) secs\n }"
       return description
    }
    
    var mark = "✅😊"
    
    var description = "\(mark)"
    
    description.append("  RequestMethod: \(urlRequest?.httpMethod ?? "")  RequestURL: \(urlRequest?.description ?? "")")
    
    let parameters = SYNetworkingConfig.sharedInstance.uniformParameters?.merged(with: request.requestParameters) ?? request.requestParameters
    var parametersString = ""
    if let jsonParameters = parameters,let string = JSON(jsonParameters).rawString() {
        parametersString = string
    }
    description.append(" \n\n↑↑↑↑ [REQUEST]: \n\n\(parametersString)")
    
    description.append(" \n\n↓↓↓↓ [RESPONSE]: \n")
    
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
        description.append(" Timeline⏰⏰: \n\(generateTimelineResponseDescription(timeline: timeline))\n\nError❗️: \(error.localizedDescription)")
        return description
    }
    var resultJSONString: String?
    if let resultData = data {
        resultJSONString = JSON(resultData).rawString()
    }
    description.append("\nData: \(data?.count ?? 0) bytes\n\nResult: \(resultJSONString ?? "")\n\nTimeline⏰⏰: \n\(generateTimelineResponseDescription(timeline: timeline))")
    
    return description
}

