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
    
    public var error: Error?
}

public protocol ResponseDescription {
    
    var responseCommon: ResponseCommon? { get }
    
    func responseDescriptionFormat(_ request: SYRequest) -> String
}


//MARK: - DataResponse

extension DataResponse: ResponseDescription {
    
    public func responseDescriptionFormat(_ request: SYRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, data: self.data, error: self.error, networkTime: self.metrics.map({ return $0.taskInterval.duration }) ?? TimeInterval(0), serializationTime:self.serializationDuration)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, error: self.error)
    }
}

//MARK: - DownloadResponse

extension DownloadResponse: ResponseDescription {
    
    public func responseDescriptionFormat(_ request: SYRequest) -> String {
        return generateResponseDescription(request, urlRequest: self.request, response: self.response, fileURL: self.fileURL, resumeData: self.resumeData, error: self.error, networkTime: self.metrics.map({ return $0.taskInterval.duration }) ?? TimeInterval(0), serializationTime: self.serializationDuration)
    }
    
    public var responseCommon: ResponseCommon? {
        return ResponseCommon(request: self.request, response: self.response, error: self.error)
    }
}

func generateResponseDescription(_ request: SYRequest, urlRequest: URLRequest?, response: HTTPURLResponse?, fileURL: URL? = nil, resumeData: Data? = nil, data: Data? = nil, error: Error?, networkTime: TimeInterval, serializationTime: TimeInterval) -> String {
    
    func generateTimelineResponseDescription(networkTime: TimeInterval,serializationTime: TimeInterval) -> String {
        let totalDuration = (networkTime + serializationTime)
        let totalDurationString = String(format: "%.6f", totalDuration)
        let description = "{ \n  Request Duration: \(String(format: "%.6f", networkTime)) secs\n  Serialization Duration: \(String(format: "%.6f", serializationTime)) secs\n  Total Duration: \(totalDurationString) secs\n }"
       return description
    }
    
    var mark = "✅😊"
    
    var description = "\(mark)"
    
    description.append("  RequestMethod: \(urlRequest?.httpMethod ?? "")  RequestURL: \(urlRequest?.description ?? "")")
    
    let parameters = SYNetworkingConfig.sharedInstance.uniformParameters?.merged(with: request.parameters) ?? request.parameters
    var parametersString = ""
    if let jsonParameters = parameters,let string = JSON(jsonParameters).rawString() {
        parametersString = string
    }
    description.append(" \n\n↑↑↑↑ [REQUEST]: \n\n\(parametersString)")
    
    description.append(" \n\n↓↓↓↓ [RESPONSE]: \n")
    
    if let fileURL = fileURL {
        description.append("\nFileURL: \(fileURL.absoluteString)")
    }
    
    if let resumeData = resumeData {
        description.append("\nResumeData: \(resumeData.count) bytes")
    }
    
    if let error = error {
        mark = "❌😟"
        description.append(" Timeline⏰⏰: \n\(generateTimelineResponseDescription(networkTime: networkTime, serializationTime: serializationTime))\n\nError❗️: \(error.localizedDescription)")
        return description
    }
    var resultJSONString: String?
    if let resultData = data {
        resultJSONString = JSON(resultData).rawString()
    }
    description.append("\nData: \(data?.count ?? 0) bytes\n\nResult: \(resultJSONString ?? "")\n\nTimeline⏰⏰: \n\(generateTimelineResponseDescription(networkTime: networkTime, serializationTime: serializationTime))")
    
    return description
}

