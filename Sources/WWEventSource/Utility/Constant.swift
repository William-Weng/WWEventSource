//
//  Constant.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import UIKit
import WWRegularExpression

// MARK: - typealias
public extension WWEventSource {
    
    typealias EventValue = (keyword: Keyword, value: String, rawValue: String)      // (事件類型, 事件值, 原始值)
    typealias RawInformation = (data: Data, response: HTTPURLResponse)              // (原始資料, HTTP回應)
}

// MARK: - 常數
public extension WWEventSource {
        
    /// [SSE的連線狀態](https://www.ruanyifeng.com/blog/2017/05/server-sent_events.html)
    enum ConnectionStatus {
        
        case connecting
        case open
        case closed
    }
    
    /// SSE事件關鍵字
    enum Event {
        
        case id(_ keyword: Keyword, _ value: Int)
        case event(_ keyword: Keyword, _ value: String)
        case retry(_ keyword: Keyword, _ value: Int)
        case data(_ keyword: Keyword, _ value: String)
    }
    
    /// SSE訊息關鍵字
    enum Keyword: CaseIterable {
        
        case id     // id: <事件序號>\n
        case event  // event: <錯誤訊息>\n
        case retry  // retry: <重新連結秒數>\n
        case data   // data: <訊息>\n\n
        
        /// 解析事件文字 (data: 文字\n\n => 文字)
        /// - Parameters:
        ///   - eventString: 原始文字
        /// - Returns: Result<[String]?, Error>
        func parseEventString(_ eventString: String) -> Result<[String]?, Error> {
            
            let pattern = "(?<=\(self.prefix()) ).*"
            let result = WWRegularExpression.Method.extracts(text: eventString, pattern: pattern).calculate()
            
            return result
        }
        
        /// 事件前綴字 (data / event)
        /// - Returns: String
        func prefix() -> String {
            
            switch self {
            case .id: return "id:"
            case .event: return "event:"
            case .retry: return "retry:"
            case .data: return "data:"
            }
        }
    }
    
    /// 自訂錯誤
    enum CustomError: Error, LocalizedError {
        
        var errorDescription: String { errorMessage() }

        case isEmpty
        case notEncoding
        case notUrlFormat
        case notHttpResponse
        
        /// 顯示錯誤說明
        /// - Returns: String
        private func errorMessage() -> String {
            
            switch self {
            case .isEmpty: return "空值"
            case .notEncoding: return "文字編碼格式錯誤"
            case .notUrlFormat: return "URL格式錯誤"
            case .notHttpResponse: return "不是標準HTTP回應"
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
    
    /// [HTTP Content-Type](https://www.runoob.com/http/http-content-type.html) => Content-Type: application/json
    enum ContentType: CustomStringConvertible {
        
        public var description: String { return toString() }
        
        case plain
        case html
        case xml
        case json
        case png
        case jpeg
        case formUrlEncoded
        case formData(boundary: String)
        case flac
        case mp3
        case mp4
        case mpeg
        case mpga
        case m4a
        case ogg
        case wav
        case webm
        case octetStream
        case bearer(forKey: String)
        case custom(value: String)
        
        /// [轉成MIME文字](https://developer.mozilla.org/zh-TW/docs/Web/HTTP/Basics_of_HTTP/MIME_types)
        /// - Returns: [String](https://www.iana.org/assignments/media-types/media-types.xhtml)
        private func toString() -> String {
            
            switch self {
            case .plain: return "text/plain"
            case .html: return "text/html"
            case .xml: return "text/xml"
            case .json: return "application/json"
            case .png: return "image/png"
            case .jpeg: return "image/jpeg"
            case .mp3: return "audio/mpeg"
            case .mpeg: return "audio/mpeg"
            case .mpga: return "audio/mpeg"
            case .mp4: return "audio/mp4"
            case .ogg: return "audio/ogg"
            case .wav: return "audio/wav"
            case .webm: return "audio/webm"
            case .m4a: return "audio/m4a"
            case .flac: return "audio/flac"
            case .formUrlEncoded: return "application/x-www-form-urlencoded"
            case .formData(boundary: let boundary): return "multipart/form-data; boundary=\(boundary)"
            case .octetStream: return "application/octet-stream"
            case .bearer(forKey: let key): return "Bearer \(key)"
            case .custom(value: let value): return value
            }
        }
    }
}
