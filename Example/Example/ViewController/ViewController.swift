//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2024/11/8.
//
//

import UIKit
import WWEventSource

// MARK: - ViewController
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

// MARK: - WWEventSourceDelegate
extension ViewController: WWEventSource.Delegate {
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, Error>) {
        print(result)
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, rawString: String) {
        print(rawString)
    }
    
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.EventValue) {
        
        switch eventValue.keyword {
        case .id: print(eventValue)
        case .event: print(eventValue)
        case .retry: print(eventValue)
        case .data: print(eventValue)
            tempMessage += eventValue.value
            DispatchQueue.main.async { self.eventStringLabel.text = self.tempMessage }
        }
    }
}
