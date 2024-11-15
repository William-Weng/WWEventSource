//
//  WWEventSourceDelegate.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import AVFoundation

// MARK: - WWEventSourceDelegate
public protocol WWEventSourceDelegate: NSObjectProtocol {
    
    /// 接收從Server端傳來的事件訊息 (event: <訊息>\n)
    func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.Constant.EventValue)
    
    /// 接收從Server端傳來的原始訊息 (data: <訊息>\n\n)
    func serverSentEvents(_ eventSource: WWEventSource, rawString: String)
    
    /// 接收連線的狀態
    func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.Constant.ConnectionStatus, Error>)
}
