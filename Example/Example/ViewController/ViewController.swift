//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2024/11/8.
//
//

import UIKit
import WWEventSource
import WWPrint

// MARK: - ViewController
final class ViewController: UIViewController {

    @IBOutlet weak var eventStringLabel: UILabel!
    
    private let urlString = "http://192.168.4.92:12345/sse"
    private var tempString = ""
    
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
    
    func serverSentEvents(_ eventSource: WWEventSource, eventString: String) {
        tempString += eventString
        DispatchQueue.main.async { self.eventStringLabel.text = self.tempString }
    }
    
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<Constant.ConnectionStatus, Error>) {
        switch result {
        case .failure(let error): wwPrint(error)
        case .success(let status): wwPrint(status)
        }
    }
}

