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
        _ = WWEventSource.shared.connect(httpMethod: .POST, delegate: self, urlString: urlString, httpBodyType: .dictionary(dictionary))
    }
}

// MARK: - WWEventSourceDelegate
extension ViewController: WWEventSourceDelegate {
    
    func serverSentEvents(_ eventSource: WWEventSource, rawString: String) {
        
        let result = eventSource.parseRawString(rawString, keyword: .data)
        
        switch result {
        case .failure(let error): wwPrint(error)
        case .success(let array):
            
            guard let message = array?.first else { return }
            
            tempMessage += message
            DispatchQueue.main.async { self.eventStringLabel.text = self.tempMessage }
        }
    }
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.Constant.ConnectionStatus, Error>) {
        switch result {
        case .failure(let error): wwPrint(error)
        case .success(let status): wwPrint(status)
        }
    }
}

