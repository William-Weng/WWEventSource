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
    
    open class Constant: NSObject {}
    
    public static let shared: WWEventSource = WWEventSource()
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    private var receivedData = Data()
    
    public weak var delegate: WWEventSourceDelegate?
    
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
    ///   - parameters: [[String: String?]?](https://github.com/hamin/EventSource.Swift/blob/master/lib/SwiftEventSource.swift)
    ///   - headers: [[String: String?]?](https://blog.gtwang.org/web-development/stream-updates-with-server-sent-events/)
    ///   - httpBodyType: Constant.HttpBobyType?
    ///   - configuration: URLSessionConfiguration
    ///   - queue: OperationQueue?
    /// - Returns: Result<URLSessionDataTask?, Error>
    func connect(httpMethod: Constant.HttpMethod = .GET, delegate: WWEventSourceDelegate?, urlString: String, parameters: [String: String?]? = nil, headers: [String: String?]? = nil, httpBodyType: Constant.HttpBobyType? = nil, configuration: URLSessionConfiguration = .default, queue: OperationQueue? = nil) -> Result<URLSessionDataTask?, Error> {
        return connect(httpMethod: httpMethod, delegate: delegate, urlString: urlString, queryItems: parameters?._queryItems(), headers: headers, httpBodyType: httpBodyType, configuration: configuration, queue: queue)
    }
    
    /// [關閉SSE連線](https://blackbing.medium.com/淺談-server-sent-events-9c81ef21ca8e)
    func disconnect() {
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.closed))
        delegate = nil
        dataTask?.cancel()
        session?.invalidateAndCancel()
    }
}

// MARK: - URLSessionDataDelegate
extension WWEventSource: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        defer { receivedData.removeAll() }
        
        delegate?.serverSentEventsConnectionStatus(self, result: .success(.open))
        receivedData.append(data)
        parseEvents(with: receivedData)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
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
    ///   - queryItems: [URLQueryItem]?
    ///   - headers: [String: String?]?
    ///   - httpBodyType: Constant.HttpBobyType?
    ///   - configuration: URLSessionConfiguration
    ///   - queue: OperationQueue?
    /// - Returns: Result<URLSessionDataTask?, Error>
    func connect(httpMethod: Constant.HttpMethod, delegate: WWEventSourceDelegate?, urlString: String, queryItems: [URLQueryItem]?, headers: [String: String?]?, httpBodyType: Constant.HttpBobyType?, configuration: URLSessionConfiguration, queue: OperationQueue?) -> Result<URLSessionDataTask?, Error> {
        
        guard let urlComponents = URLComponents._build(urlString: urlString, queryItems: queryItems),
              let queryedURL = urlComponents.url,
              var request = Optional.some(URLRequest._build(url: queryedURL, httpMethod: httpMethod))
        else {
            return .failure(Constant.MyError.notUrlFormat)
        }
        
        self.delegate = delegate
                
        if let headers = headers {
            headers.forEach { key, value in if let value = value { request.addValue(value, forHTTPHeaderField: key) }}
        }
        
        request.httpBody = httpBodyType?.data()
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
        
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.connecting))
        return .success(dataTask)
    }
    
    /// 解析傳來的事件值
    /// - Parameter receivedData: Data
    func parseEvents(with receivedData: Data) {
        
        guard let rawString = String(data: receivedData, encoding: .utf8) else { return }
        
        var eventValues: [Constant.EventValue] = []
        
        delegate?.serverSentEvents(self, rawString: rawString)
        
        parseEventArray(rawString: rawString).forEach { event in
            
            for keyword in Constant.Keyword.allCases {
                guard let value = try? parseEventString(event, keyword: keyword).get() else { continue }
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
        
        let keywords = Constant.Keyword.allCases.map { $0.prefix() }.joined(separator: "|")
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
    func parseEventString(_ eventString: String, keyword: Constant.Keyword) -> Result<String?, Error> {
        
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
