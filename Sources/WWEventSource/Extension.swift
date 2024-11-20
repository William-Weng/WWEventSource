//
//  Extension.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import UIKit

// MARK: - String (function)
extension String {
    
    /// String => Data
    /// - Parameters:
    ///   - encoding: 字元編碼
    ///   - isLossyConversion: 失真轉換
    /// - Returns: Data?
    func _data(using encoding: String.Encoding = .utf8, isLossyConversion: Bool = false) -> Data? {
        let data = self.data(using: encoding, allowLossyConversion: isLossyConversion)
        return data
    }
}

// MARK: - Sequence (function)
extension Sequence {
        
    /// Array => JSON Data
    /// - ["name","William"] => ["name","William"] => 5b226e616d65222c2257696c6c69616d225d
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
}

// MARK: - Dictionary (function)
extension Dictionary {
    
    /// Dictionary => JSON Data
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Returns: Data?
    func _jsonData(options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        return JSONSerialization._data(with: self, options: options)
    }
}

// MARK: - Dictionary (function)
extension Dictionary where Self.Key == String, Self.Value == String? {
    
    /// [將[String: String?] => [URLQueryItem]](https://medium.com/@jerrywang0420/urlsession-教學-swift-3-ios-part-2-a17b2d4cc056)
    /// - ["name": "William.Weng", "github": "https://william-weng.github.io/"] => ?name=William.Weng&github=https://william-weng.github.io/
    /// - Returns: [URLQueryItem]
    func _queryItems() -> [URLQueryItem]? {
        
        if self.isEmpty { return nil }
        
        var queryItems: [URLQueryItem] = []

        for (key, value) in self {
            
            guard let value = value else { continue }
            
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        
        return queryItems
    }
}

// MARK: - JSONSerialization (static function)
extension JSONSerialization {
    
    /// [JSONObject => JSON Data](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/利用-jsonserialization-印出美美縮排的-json-308c93b51643)
    /// - ["name":"William"] => {"name":"William"} => 7b226e616d65223a2257696c6c69616d227d
    /// - Parameters:
    ///   - object: Any
    ///   - options: JSONSerialization.WritingOptions
    /// - Returns: Data?
    static func _data(with object: Any, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions()) -> Data? {
        
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: options)
        else {
            return nil
        }
        
        return data
    }
}


// MARK: - URLRequest (static function)
extension URLRequest {
    
    /// 產生URLRequest
    /// - Parameters:
    ///   - url: URL網址
    ///   - httpMethod: HTTP方法 (GET / POST / ...)
    static func _build(url: URL, httpMethod: Constant.HttpMethod? = nil) -> URLRequest {
        return Self._build(url: url, httpMethod: httpMethod?.rawValue)
    }
    
    /// 產生URLRequest
    /// - Parameters:
    ///   - url: URL網址
    ///   - httpMethod: HTTP方法 (GET / POST / ...)
    static func _build(url: URL, httpMethod: String? = nil) -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        return request
    }
}

// MARK: - URLComponents (static function)
extension URLComponents {
    
    /// 產生URLComponents
    /// - Parameters:
    ///   - urlString: UrlString
    ///   - queryItems: Query參數
    /// - Returns: URLComponents?
    static func _build(urlString: String, queryItems: [URLQueryItem]? = nil) -> URLComponents? {
        
        guard var urlComponents = URLComponents(string: urlString) else { return nil }
                        
        if let queryItems = queryItems {
            
            let urlComponentsQueryItems = urlComponents.queryItems ?? []
            let newQueryItems = (urlComponentsQueryItems + queryItems)
            
            urlComponents.queryItems = newQueryItems
        }
        
        return urlComponents
    }
}
