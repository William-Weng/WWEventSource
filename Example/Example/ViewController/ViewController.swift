//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2024/11/8.
//
//

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
