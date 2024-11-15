//
//  WWEventSource.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import UIKit

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
    
    /// 解析原始文字 ("data: 文字\n\n" => 文字)
    /// - Parameters:
    ///   - rawString: 原始文字
    ///   - keyword: Constant.Keyword
    ///   - newlineCount: 結尾"\n"的數量
    /// - Returns: Result<[String]?, Error>
    func parseRawString(_ rawString: String, keyword: Constant.Keyword, newlineCount: UInt = 2) -> Result<[String]?, Error> {
        return keyword.parseRawString(rawString, newlineCount: newlineCount)
    }
}

// MARK: - URLSessionDataDelegate
extension WWEventSource: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        
        receivedData.append(data)
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.open))
        
        if let rawString = String(data: receivedData, encoding: .utf8) {
            delegate?.serverSentEvents(self, rawString: rawString)
            receivedData.removeAll()
        }
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
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.addValue("text/event-stream", forHTTPHeaderField: "Accept")

        session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
        
        self.delegate?.serverSentEventsConnectionStatus(self, result: .success(.connecting))
        return .success(dataTask)
    }
}
