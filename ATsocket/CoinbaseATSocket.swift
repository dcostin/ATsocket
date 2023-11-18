//
//  CoinbaseATSocket.swift
//  ATsocket
//
//  Created by Dan Costin on 11/18/23.
//

import Foundation

class CoinbaseATSocket : ObservableObject {
    
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
        self.connect()
        self.subscribe()
    }
    
    func connect(wsURL: String = "wss://advanced-trade-ws.coinbase.com") {
        Log.Log("WebSocket connecting to \(wsURL)")
        // WebSocket connecting to wss://advanced-trade-ws.coinbase.com
        
        let request = URLRequest(url: URL(string: wsURL)!)
        
        socket = session.webSocketTask(with: request)
        
        listen()
        socket.resume()
    }
    
    func subscribe() {
        let subscribeRequest = CoinbaseAuthentication.authenticate(subscription)
        
        do {
            let data = try encoder.encode(subscribeRequest)
            
            Log.Log("Sending \(String(decoding: data, as: UTF8.self))")
            
            self.socket.send(.data(data)) { error in
                if let error = (error as NSError?) {
                    Log.Log("Error starting subscription: \(error.localizedDescription)")
                } else {
                    Log.Log("Websocket message sent: \(String(decoding: data, as: UTF8.self))")
                }
            }
        } catch {
            Log.Log("Failed to decode subscription message: \(error)")
        }
    }
    
    
    func listen() {
        self.socket.receive { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                Log.Log("Socket listen error: \(error)")
                // Coinbase Socket listen error: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=wss://advanced-trade-ws.coinbase.com/, NSErrorFailingURLKey=wss://advanced-trade-ws.coinbase.com/}

                return
                
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handle(data)
                case .string(let str):
                    guard let data = str.data(using: .utf8) else { return }
                    self.handle(data)
                @unknown default:
                    break
                }
            }
            self.listen()
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
            case "ticker":
                Log.Log("Ticker data coming in")
            case "heartbeat":
                Log.Log("Heartbeat data coming in")
            case "error":
                let errorMsg = try decoder.decode(ErrorReasonMsg.self, from: data)
                Log.Log("!!!!!!!!! ERROR: \(errorMsg.message) -- \(errorMsg.reason)")
                
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
