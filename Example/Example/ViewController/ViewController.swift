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
    
    private let urlString = "http://localhost:54321/sse"
    private var tempMessage = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func sseTest(_ sender: UIBarButtonItem) {
        let dictionary: [String : Any] = ["content": "We’ve trained a model called ChatGPT which interacts in a conversational way. The dialogue format makes it possible for ChatGPT to answer followup questions, admit its mistakes, challenge incorrect premises, and reject inappropriate requests.", "delayTime": 0.05]
        tempMessage = ""
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .dictionary(dictionary))
    }
}

// MARK: - WWEventSourceDelegate
extension ViewController: WWEventSourceDelegate {
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<Constant.ConnectionStatus, Error>) {
        wwPrint(result)
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, rawString: String) {
        wwPrint(rawString)
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: Constant.EventValue) {
        
        switch eventValue.keyword {
        case .id: wwPrint(eventValue)
        case .event: wwPrint(eventValue)
        case .retry: wwPrint(eventValue)
        case .data: wwPrint(eventValue)
            tempMessage += eventValue.value
            DispatchQueue.main.async { self.eventStringLabel.text = self.tempMessage }
        }
    }
}
