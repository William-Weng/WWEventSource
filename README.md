# WWEventSource
[![Swift-5.7](https://img.shields.io/badge/Swift-5.7-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-15.0](https://img.shields.io/badge/iOS-15.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWEventSource) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction - 簡介](https://swiftpackageindex.com/William-Weng)
- [Use URLSession to implement the functions of the SSE client and receive information from the SSE server.]()
- [使用URLSession來實作SSE的Client端的功能，可以接收SSE Server端傳來的資訊。](https://apifox.com/apiskills/sse-vs-websocket/)

https://github.com/user-attachments/assets/ee734f09-1d81-4bb4-b3a7-2bc08c16f7e8

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)
```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWEventSource.git", .upToNextMajor(from: "1.4.2"))
]
```

### Parameters - 可用參數
|參數|功能|
|-|-|
|lastEventId|紀錄最後的事件Id|
|lastRertyTime|紀錄最後的重試時間 (ms)|

### Function - 可用函式
|函式|功能|
|-|-|
|connect(httpMethod:delegate:urlString:contentType:using:parameters:headers:httpBodyType:configuration:queue:)|開啟SSE連線|
|disconnect()|關閉SSE連線|

### [WWEventSource.Delegate](https://ezgif.com/video-to-webp)
|函式|功能|
|-|-|
|serverSentEventsConnectionStatus(_:result:)|接收連線的狀態|
|serverSentEventsRawData(_:result:)|接收從Server端傳來的原始訊息|
|serverSentEvents(_:eventValue:)|接收從Server端傳來的事件訊息|

### Example
```swift
import UIKit
import WWEventSource

final class ViewController: UIViewController {

    @IBOutlet weak var eventStringLabel: UILabel!
    
    private let urlString = "http://localhost:54321/sse"
    private var tempMessage = ""
    
    @IBAction func sseTest(_ sender: UIBarButtonItem) {
        let dictionary: [String : Any] = ["content": "We’ve trained a model called ChatGPT which interacts in a conversational way. The dialogue format makes it possible for ChatGPT to answer followup questions, admit its mistakes, challenge incorrect premises, and reject inappropriate requests.", "delayTime": 0.05]
        tempMessage = ""
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .dictionary(dictionary))
    }
}

extension ViewController: WWEventSource.Delegate {
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, any Error>) {
        print(result)
    }
    
    func serverSentEventsRawData(_ eventSource: WWEventSource, result: Result<WWEventSource.RawInformation, any Error>) {
        
        switch result {
        case .failure(let error): print(error)
        case .success(let rawInformation): print(rawInformation)
        }
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.EventValue) {
        
        switch eventValue.keyword {
        case .id: print(eventValue)
        case .event: print(eventValue)
        case .retry: print(eventValue)
        case .data: tempMessage += eventValue.value; eventStringLabel.text = tempMessage
        }
    }
}
```

### 網路測試環境
```
python3 -m venv .venv
source ./venv/bin/activate
pip install flask requests rich
python3 sse.py
```

