//
//  Delegate.swift
//  WWEventSource
//
//  Created by William.Weng on 2024/11/8.
//

import AVFoundation

// MARK: - WWEventSource.Delegate
public extension WWEventSource {
    
    public protocol Delegate: NSObjectProtocol {
        
        /// 接收連線的狀態
        func serverSentEventsConnectionStatus(_ eventSource: WWEventSource, result: Result<WWEventSource.ConnectionStatus, Error>)
        
        /// 接收從Server端傳來的原始訊息 (data: <訊息>\n\n)
        func serverSentEventsRawData(_ eventSource: WWEventSource, result: Result<RawInformation, Error>)
        
        /// 接收從Server端傳來的事件訊息 (event, 訊息)
        func serverSentEvents(_ eventSource: WWEventSource, eventValue: WWEventSource.EventValue)
    }
}
