//
//  WWEventSource.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import UIKit
import WWRegularExpression

// MARK: - WWEventSource
open class WWEventSource: NSObject {
        
    public static let shared: WWEventSource = WWEventSource()
    
    public private(set) var lastEventId: Int?       // 紀錄最後的事件Id
    public private(set) var lastRertyTime: Int?     // 紀錄最後的重試時間 (ms)
    
    private var encoding: String.Encoding = .utf8
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    
    public weak var delegate: Delegate?
    
    deinit {
        delegate = nil
        print("WWEventSource - deinit")
    }
}

// MARK: - 公開函式
public extension WWEventSource {
    
    /// [開啟SSE連線](https://github.com/Recouse/EventSource)
    /// - Parameters:
    ///   - httpMethod: [Http方法](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)
    ///   - delegate: [WWEventSourceDelegate?](https://apifox.com/apiskills/sse-vs-websocket/)
    ///   - urlString: [String](https://ithelp.ithome.com.tw/articles/10230335)
    ///   - contentType: [ContentType](https://www.runoob.com/http/http-content-type.html)
    ///   - encoding: [String.Encoding](https://www.w3schools.com/html/html_charset.asp)
    ///   - parameters: [[String: String?]?](https://github.com/hamin/EventSource.Swift/blob/master/lib/SwiftEventSource.swift)
    ///   - headers: [[String: String?]?](https://blog.gtwang.org/web-development/stream-updates-with-server-sent-events/)
    ///   - httpBodyType: Constant.HttpBobyType?
    ///   - configuration: URLSessionConfiguration
    ///   - queue: OperationQueue?
    /// - Returns: Result<URLSessionDataTask?, Error>
    func connect(httpMethod: WWEventSource.HttpMethod = .GET, delegate: Delegate?, urlString: String, contentType: ContentType = .json, using encoding: String.Encoding = .utf8, parameters: [String: String?]? = nil, headers: [String: String?]? = nil, httpBodyType: WWEventSource.HttpBobyType? = nil, configuration: URLSessionConfiguration = .default, queue: OperationQueue? = nil) -> Result<URLSessionDataTask?, Error> {
        return connect(httpMethod: httpMethod, delegate: delegate, urlString: urlString, contentType: contentType, encoding: encoding, queryItems: parameters?._queryItems(), headers: headers, httpBodyType: httpBodyType, configuration: configuration, queue: queue)
    }
    
    /// [關閉SSE連線](https://blackbing.medium.com/淺談-server-sent-events-9c81ef21ca8e)
    func disconnect() {
        delegate = nil
        dataTask?.cancel()
        session?.invalidateAndCancel()
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.closed))
    }
}

// MARK: - URLSessionDataDelegate
extension WWEventSource: URLSessionDataDelegate {}
public extension WWEventSource {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        defer { receivedData.removeAll() }
        
        let response = dataTask.response as? HTTPURLResponse
        
        delegate?.serverSentEventsConnectionStatus(self, result: .success(.open))
        receivedData.append(data)
        parseEvents(with: receivedData, encoding: encoding, response: response)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                
        if let error = error { self.delegate?.serverSentEventsConnectionStatus(self, result: .failure(error)); return }
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.closed))
    }
}

// MARK: - 小工具
private extension WWEventSource {
    
    /// SSE連線
    /// - Parameters:
    ///   - httpMethod: Constant.HttpMethod
    ///   - delegate: WWEventSourceDelegate?
    ///   - urlString: String
    ///   - contentType: ContentType
    ///   - encoding: String.Encoding
    ///   - queryItems: [URLQueryItem]?
    ///   - headers: [String: String?]?
    ///   - httpBodyType: Constant.HttpBobyType?
    ///   - configuration: URLSessionConfiguration
    ///   - queue: OperationQueue?
    /// - Returns: Result<URLSessionDataTask?, Error>
    func connect(httpMethod: HttpMethod, delegate: Delegate?, urlString: String, contentType: ContentType, encoding: String.Encoding, queryItems: [URLQueryItem]?, headers: [String: String?]?, httpBodyType: WWEventSource.HttpBobyType?, configuration: URLSessionConfiguration, queue: OperationQueue?) -> Result<URLSessionDataTask?, Error> {
        
        guard let urlComponents = URLComponents._build(urlString: urlString, queryItems: queryItems),
              let queryedURL = urlComponents.url,
              var request = Optional.some(URLRequest._build(url: queryedURL, httpMethod: httpMethod))
        else {
            return .failure(CustomError.notUrlFormat)
        }
        
        lastEventId = nil
        lastRertyTime = 3000
        self.delegate = delegate
        self.encoding = encoding
        
        request.httpBody = httpBodyType?.data()
        request.addValue("\(contentType)", forHTTPHeaderField: "Content-Type")
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        if let headers { headers.forEach { key, value in if let value = value { request.addValue(value, forHTTPHeaderField: key) }}}
        
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
        
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.connecting))
        
        return .success(dataTask)
    }
    
    /// 解析傳來的事件值
    /// - Parameters:
    ///   - receivedData: 原始資料
    ///   - encoding: 字元編碼
    ///   - response: URLResponse?
    func parseEvents(with receivedData: Data, encoding: String.Encoding, response: HTTPURLResponse?) {
        
        guard let response = response else { delegate?.serverSentEventsRawString(self, result: .failure(CustomError.notHttpResponse)); return }
        guard let rawString = String(data: receivedData, encoding: encoding) else { delegate?.serverSentEventsRawString(self, result: .failure(CustomError.notEncoding)); return }
        
        var eventValues: [EventValue] = []
        
        delegate?.serverSentEventsRawString(self, result: .success((rawString, response)))
        
        parseEventArray(rawString: rawString).forEach { event in
            
            for keyword in Keyword.allCases {
                
                guard let value = try? parseEventString(event, keyword: keyword).get() else { continue }
                                
                switch keyword {
                case .id: lastEventId = Int(value) ?? lastEventId
                case .retry: lastRertyTime = Int(value) ?? lastRertyTime
                case .event, .data: break
                }
                
                eventValues.append((keyword, value, event))
            }
        }
        
        eventValues.forEach { delegate?.serverSentEvents(self, eventValue: $0) }
    }
    
    /// 解析傳來的SSE事件文字訊息 (id: 123\nevent: 英\r文字\ndata: 中\n文\r字\n\n =>  ["id: 123\n", "event: 英\r文字\n", "data: 中\n文\r字\n\n"])
    /// - Parameter rawString: String
    /// - Returns: [String]
    func parseEventArray(rawString: String) -> [String] {
                
        var eventArray: [String] = []
        var _array: [String] = []
        
        rawString.components(separatedBy: "\n").forEach { string in
            
            let isMatche = matche(rawString: string)
            if (isMatche) { eventArray.append("\(string)\n"); return }
            
            if (!_array.isEmpty) {
                
                guard let lastEvent = eventArray.popLast(),
                      let _event = Optional.some(_array.joined(separator: ""))
                else {
                    return
                }
                
                eventArray.append("\(lastEvent)\(_event)")
                _array = []
            }
            
            _array.append("\(string)\n")
        }
        
        return eventArray
    }
    
    /// 測試看看文字是否符合SSE的格式 => id:/event:/data:開頭的
    /// - Parameter rawString: String
    /// - Returns: Bool
    func matche(rawString: String) -> Bool {
        
        let keywords = Keyword.allCases.map { $0.prefix() }.joined(separator: "|")
        let pattern = "^[\(keywords)].*"
        let result = WWRegularExpression.Method.extracts(text: rawString, pattern: pattern).calculate()
        
        switch result {
        case .failure(_): return false
        case .success(let array):
            
            guard let array = array,
                  !array.isEmpty
            else {
                return false
            }
            
            return true
        }
    }
    
    /// 解析事件文字 ("data: 文字\n\n" => 文字)
    /// - Parameters:
    ///   - rawString: 事件文字
    ///   - keyword: Constant.Keyword
    /// - Returns: Result<[String]?, Error>
    func parseEventString(_ eventString: String, keyword: Keyword) -> Result<String?, Error> {
        
        let result = keyword.parseEventString(eventString)
                
        switch result {
        case .failure(let error): return .failure(error)
        case .success(let array):
            
            guard let array = array,
                  let value = array.first
            else {
                return .success(nil)
            }
            
            return .success(value)
        }
    }
}
