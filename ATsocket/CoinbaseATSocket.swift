//
//  CoinbaseATSocket.swift
//  ATsocket
//
//  Created by Dan Costin on 11/18/23.
//

import Foundation
import SwiftUI

class CoinbaseATSocket : ObservableObject {
    @ObservedObject var global = MsgTxt.global
    
    private let session: URLSession
    var socket: URLSessionWebSocketTask!
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    struct Subscription: Encodable {
        let type = "subscribe"
        var product_ids = [ "BTC-USD" ]
        var channel = "ticker"
        // AUTHENTICATION
        var api_key : String = ""
        var timestamp : String = ""
        var signature : String = ""
    }
    
    var subscription: Subscription
    
    init() {
        self.session = URLSession(configuration: .default)
        subscription = Subscription()
        
        // if sent to another websocket address, at least get back error message, uncomment desired line to try out
        self.connect()
//        self.connect("wss://ws-feed.exchange.coinbase.com")
        
        global.textMsg += "\nSubscribing..."
        self.subscribe()
    }
    
    func connect(_ wsURL: String = "wss://advanced-trade-ws.coinbase.com") {
        Log.Log("WebSocket connecting to \(wsURL)")
        // WebSocket connecting to wss://advanced-trade-ws.coinbase.com
        global.textMsg += "\nWebSocket connecting to \(wsURL)\n"
        
        let request = URLRequest(url: URL(string: wsURL)!)
        
        socket = session.webSocketTask(with: request)
        
        global.textMsg += "\nListening..."
        listen()
        socket.resume()
    }
    
    func subscribe() {
        let subscribeRequest = CoinbaseAuthentication.authenticate(subscription)
        
        do {
            let data = try encoder.encode(subscribeRequest)
            
            Log.Log("Sending \(String(decoding: data, as: UTF8.self))")
            global.textMsg += "\n\nSending \(String(decoding: data, as: UTF8.self))\n"
            
            self.socket.send(.data(data)) { error in
                DispatchQueue.main.sync {
                    if let error = (error as NSError?) {
                        Log.Log("Error starting subscription: \(error.localizedDescription)")
                        self.global.textMsg += "\nError starting subscription: \(error.localizedDescription)"
                    } else {
                        Log.Log("Websocket message sent: \(String(decoding: data, as: UTF8.self))")
                        self.global.textMsg += "\nWebsocket message sent: \(String(decoding: data, as: UTF8.self))\n"
                    }
                }
            }
        } catch {
            Log.Log("Failed to decode subscription message: \(error)")
        }
    }
    
    
    func listen() {
        self.socket.receive { (result) in
            DispatchQueue.main.sync {
                switch result {
                case .failure(let error):
                    Log.Log("Socket listen error: \(error)")
                    self.global.textMsg += "\nSocket listen error: \(error)\n"
                    // Coinbase Socket listen error: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=wss://advanced-trade-ws.coinbase.com/, NSErrorFailingURLKey=wss://advanced-trade-ws.coinbase.com/}
                    return
                    
                case .success(let message):
                    self.global.textMsg += "\nSocket message received"
                    
                    switch message {
                    case .data(let data):
                        self.global.textMsg += " as data: \(String(decoding: data, as: UTF8.self))"
                        
                        self.handle(data)
                    case .string(let str):
                        self.global.textMsg += " as string: \(str)"
                        guard let data = str.data(using: .utf8) else { return }
                        self.handle(data)
                    @unknown default:
                        self.global.textMsg += " in unknown format"
                        break
                    }
                }
                
                self.listen()
            }
        }
    }

    struct MessageType: Decodable {
        var type: String
    }
    struct ErrorReasonMsg: Decodable {
        var type: String
        var message: String
        var reason: String
    }
    
    
    func handle(_ data: Data) {
        do {
            let response = try decoder.decode(MessageType.self, from: data)
            
            switch response.type {
                
            case "subscriptions":
                Log.Log("Subscription confirmed")
                global.textMsg += "\nSubscription confirmed"
            case "ticker":
                Log.Log("Ticker data coming in")
                global.textMsg += "\nTicker data coming in"
            case "heartbeat":
                Log.Log("Heartbeat data coming in")
            case "error":
                let errorMsg = try decoder.decode(ErrorReasonMsg.self, from: data)
                Log.Log("!!!!!!!!! ERROR: \(errorMsg.message) -- \(errorMsg.reason)")
                global.textMsg += "\n\n!!!!!!!!! ERROR: \(errorMsg.message) -- \(errorMsg.reason)"
            case "status":
                Log.Log("Status data coming in")
            default:
                Log.Log("Unhandled websocket feed")
                Log.Log("\(String(data: data, encoding: .utf8) ?? "")")
                break
            }
        } catch {
            Log.Log("websocket feed error: \(error)")
        }
    }

}
