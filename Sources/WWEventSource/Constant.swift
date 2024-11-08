//
//  Constant.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import UIKit

// MARK: - Constant
open class Constant: NSObject {}

// MARK: - typealias
public extension Constant {
    
    /// [SSE的連線狀態](https://www.ruanyifeng.com/blog/2017/05/server-sent_events.html)
    enum ConnectionStatus {
        case connecting
        case open
        case closed
    }
    
    /// 自訂錯誤
    enum MyError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }

        case unknown
        case notUrlFormat
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {

            switch self {
            case .unknown: return "未知錯誤"
            case .notUrlFormat: return "URL格式錯誤"
            }
        }
    }
    
    /// [HTTP 請求方法](https://developer.mozilla.org/zh-TW/docs/Web/HTTP/Methods)
    enum HttpMethod: String {
        case GET = "GET"
        case HEAD = "HEAD"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case CONNECT = "CONNECT"
        case OPTIONS = "OPTIONS"
        case TRACE = "TRACE"
        case PATCH = "PATCH"
    }
    
    /// HttpBody的類型 (Data)
    enum HttpBobyType {
        
        case string(_ string: String?, encoding: String.Encoding = .utf8, isLossyConversion: Bool = false)
        case array(_ array: [Any]?, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions())
        case dictionary(_ dictionary: [String: Any]?, options: JSONSerialization.WritingOptions = JSONSerialization.WritingOptions())
        case custom(_ data: Data?)
        
        /// 轉成Data
        /// - Returns: Data?
        func data() -> Data? {
            
            switch self {
            case .string(let string, let encoding, let isLossyConversion): return string?._data(using: encoding, isLossyConversion: isLossyConversion)
            case .array(let array, let options): return array?._jsonData(options: options)
            case .dictionary(let dictionary, let options): return dictionary?._jsonData(options: options)
            case .custom(let data): return data
            }
        }
    }
}
