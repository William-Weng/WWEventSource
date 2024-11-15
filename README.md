# WWEventSource
[![Swift-5.6](https://img.shields.io/badge/Swift-5.6-orange.svg?style=flat)](https://developer.apple.com/swift/) [![iOS-14.0](https://img.shields.io/badge/iOS-14.0-pink.svg?style=flat)](https://developer.apple.com/swift/) ![TAG](https://img.shields.io/github/v/tag/William-Weng/WWEventSource) [![Swift Package Manager-SUCCESS](https://img.shields.io/badge/Swift_Package_Manager-SUCCESS-blue.svg?style=flat)](https://developer.apple.com/swift/) [![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

### [Introduction - 簡介](https://swiftpackageindex.com/William-Weng)
- [Use URLSession to implement the functions of the SSE client and receive information from the SSE server.]()
- [使用URLSession來實作SSE的Client端的功能，可以接收SSE Server端傳來的資訊。](https://apifox.com/apiskills/sse-vs-websocket/)

![](./Example.webp)

### [Installation with Swift Package Manager](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-spm-安裝第三方套件-xcode-11-新功能-2c4ffcf85b4b)
```bash
dependencies: [
    .package(url: "https://github.com/William-Weng/WWEventSource.git", .upToNextMajor(from: "1.1.0"))
]
```

### Function - 可用函式
|函式|功能|
|-|-|
|connect(httpMethod:delegate:urlString:parameters:headers:httpBodyType:configuration:queue:)|開啟SSE連線|
|parseRawString(_:keyword:newlineCount:)|解析原始文字|
|disconnect()|關閉SSE連線|

### WWEventSourceDelegate
|函式|功能|
|-|-|
|serverSentEvents(_:eventValue:)|接收從Server端傳來的事件訊息|
|serverSentEvents(_:eventString:)|接收從Server端傳來的原始訊息|
|serverSentEventsConnectionStatus(_:result:)|接收連線的狀態|

### Example
```swift
import UIKit
import WWPrint
import WWEventSource

// MARK: - ViewController
final class ViewController: UIViewController {

    @IBOutlet weak var eventStringLabel: UILabel!
    
    private let urlString = "http://localhost:12345/sse"
    private var tempMessage = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func sseTest(_ sender: UIBarButtonItem) {
        let dictionary: [String : Any] = ["content": "你猜猜現在是幾點？", "delayTime": 0.25]
        tempMessage = ""
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .dictionary(dictionary))
    }
}

// MARK: - WWEventSourceDelegate
extension ViewController: WWEventSourceDelegate {
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.Constant.EventValue) {
        
        switch eventValue.keyword {
        case .id: wwPrint(eventValue)
        case .event: wwPrint(eventValue)
        case .retry: wwPrint(eventValue)
        case .data:
            tempMessage += eventValue.value
            DispatchQueue.main.async { self.eventStringLabel.text = self.tempMessage }
        }
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, rawString: String) {
        
        if let event = try? eventSource.parseRawString(rawString, keyword: .event, newlineCount: 1).get()?.first { wwPrint("event = \(event)") }
        wwPrint(rawString)
    }
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.Constant.ConnectionStatus, Error>) {
        wwPrint(result)
    }
}
```


