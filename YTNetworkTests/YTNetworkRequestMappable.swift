//
//  YTNetworkRequestMappable.swift
//  YTNetworkExample
//
//  Created by Shannon Yang on 2017/1/24.
//  Copyright © 2017年 Hangzhou Yunti Technology Co. Ltd. All rights reserved.
//

import Foundation
import ObjectMapper

class WeatherResponse: Mappable {
    var location: String?
    var threeDayForecast: [Forecast]?
    var date: Date?
    
    init(){
        
    }
    
    required init?(map: Map){
    
    }
    
    func mapping(map: Map) {
        location <- map["location"]
        threeDayForecast <- map["three_day_forecast"]
    }
}

struct Forecast: Mappable {
    var day: String?
    var temperature: Int?
    var conditions: String?
    
    init(){
        
    }
    
    init?(map: Map){
        
    }
    
    mutating func mapping(map: Map) {
        day <- map["day"]
        temperature <- map["temperature"]
        conditions <- map["conditions"]
    }
}
