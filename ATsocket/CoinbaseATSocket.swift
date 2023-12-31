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
    var ticker: String
    
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
    
    init(ticker: String = "BTC-USD") {
        self.session = URLSession(configuration: .default)
        self.ticker = ticker
        
        // if sent to another websocket address, at least get back error message, uncomment desired line to try out
        self.connect()
//        self.connect("wss://ws-feed.exchange.coinbase.com")
        
        self.global.textMsg += "\nSubscribing to ticker feed for \(ticker)..."
        self.subscribe(Subscription(product_ids: [ticker], channel: "ticker"))
        
        self.global.textMsg += "\nSubscribing to heartbeat for \(ticker)..."
        self.subscribe(Subscription(product_ids: [ticker], channel: "heartbeats"))
    }
    
    func connect(_ wsURL: String = "wss://advanced-trade-ws.coinbase.com") {
        Log.Log("\(ticker) WebSocket connecting to \(wsURL)")
        // WebSocket connecting to wss://advanced-trade-ws.coinbase.com
        global.textMsg += "\n\(ticker) WebSocket connecting to \(wsURL)\n"
        
        let request = URLRequest(url: URL(string: wsURL)!)
        
        socket = session.webSocketTask(with: request)
        
        socket.resume()
        
        global.textMsg += "\n\(ticker) WebSocket listening..."
        
        listen()
    }
    
    func subscribe(_ sub: Subscription) {
        let subscribeRequest = CoinbaseAuthentication.authenticate(sub)
        
        do {
            let data = try encoder.encode(subscribeRequest)
            let message = String(decoding: data, as: UTF8.self)
            
//            Log.Log("Sending \(message)")
//            global.textMsg += "\n\nSending \(message)\n"
            
            self.socket.send(.string(message)) { error in
                DispatchQueue.main.async {
                    if let error = (error as NSError?) {
                        Log.Log("\(self.ticker) Error starting subscription: \(error.localizedDescription)")
                        self.global.textMsg += "\n\(self.ticker) Error starting subscription: \(error.localizedDescription)"
                    } else {
                        Log.Log("\(self.ticker) Websocket message sent: \(message)")
//                        self.global.textMsg += "\nWebsocket message sent: \(message)\n"
                    }
                }
            }
        } catch {
            Log.Log("\(self.ticker) Failed to decode subscription message: \(error)")
        }
    }
    
    
    func listen() {
        self.socket.receive { (result) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    Log.Log("\(self.ticker) Socket listen error: \(error)")
                    self.global.textMsg += "\n\(self.ticker) Socket listen error: \(error)\n"
                    // Coinbase Socket listen error: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=wss://advanced-trade-ws.coinbase.com/, NSErrorFailingURLKey=wss://advanced-trade-ws.coinbase.com/}
                    return
                    
                case .success(let message):
//                    self.global.textMsg += "\nSocket message received"
                    
                    switch message {
                    case .data(let data):
                        self.global.textMsg += " as data: \(String(decoding: data, as: UTF8.self))"
                        
                        self.handle(data)
                    case .string(let str):
//                        self.global.textMsg += " as string: \(str)"
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
        var channel: String
    }
    struct ErrorReasonMsg: Decodable {
        var type: String
        var message: String
    }
    
    struct TickerList: Decodable {
        var ticker : [String]? = []
        var heartbeats : [String]? = []
    }
    struct SubscriptionEvents: Decodable {
        var subscriptions: TickerList
    }
    struct SubConfirmation: Decodable {
        var channel: String
        var events: [ SubscriptionEvents ]
    }
    
    struct TickerUpdate: Decodable {
        var type: String
        var product_id: String
        var price: String
//        var best_bid: String
//        var best_ask: String
    }
    struct TickerEvent: Decodable {
        var type: String
        var tickers: [ TickerUpdate ]
    }
    struct TickerEvents: Decodable {
        var channel: String
        var timestamp: String
        var sequence_num: Int
        var events: [ TickerEvent ]
    }
    
    func handle(_ data: Data) {
        var channel = "unknown"
        
        do {
            let response = try decoder.decode(MessageType.self, from: data)
            
            channel = response.channel
            
            switch channel {
                
            case "subscriptions":
                Log.Log("\(self.ticker) Subscription confirmed")
//                Log.Log("\(String(data: data, encoding: .utf8) ?? "")")
                
                let subConfirmation = try decoder.decode(SubConfirmation.self, from: data)
                
                var subscriptions : [String] = []
                
                if subConfirmation.events.count > 0 {
                    if let t = subConfirmation.events[0].subscriptions.ticker, t.count > 0 {
                        if !global.pairNames.contains(t[0]) {
                            DispatchQueue.main.async {
                                self.global.pairNames.append(t[0]) // assumes only one ticker per websocket
                            }
                        }
                        subscriptions = ["ticker: \(t.joined(separator: ", "))"]
                    }
                    if let hb = subConfirmation.events[0].subscriptions.heartbeats, hb.count > 0 {
                        subscriptions.append("heartbeats")
                    }
                    DispatchQueue.main.async {
                        self.global.textMsg += "\n\(self.ticker) Subscription confirmed for " + subscriptions.joined(separator: "; ")
                    }
                }
                
            case "ticker":
//                Log.Log("Ticker data coming in")
//                global.textMsg += "\nTicker data coming in"
                
                let tickerEvents = try decoder.decode(TickerEvents.self, from: data)
                if tickerEvents.events.count > 0 {
                    if tickerEvents.events[0].tickers.count > 0 {
                        DispatchQueue.main.async {
                            self.global.pairValues[self.ticker] = Double(tickerEvents.events[0].tickers[0].price) ?? 0.0
                            self.global.timestamps[self.ticker] = tickerEvents.timestamp
                        }
                    }
                }
                
            case "heartbeats":
//                Log.Log("Heartbeat data coming in")
                DispatchQueue.main.async {
                    self.global.heartbeats[self.ticker] = "♥︎"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.global.heartbeats[self.ticker] = "♡"
                    }
                }
            
            case "status":
                Log.Log("\(self.ticker) Status data coming in")
                
            default:
                Log.Log("\(self.ticker) Unhandled websocket feed")
                Log.Log("\(String(data: data, encoding: .utf8) ?? "")")
                break
            }
        } catch {
            
            do {
                let errorMsg = try decoder.decode(ErrorReasonMsg.self, from: data)
                Log.Log("!!!!!!!!! \(self.ticker) ERROR: \(errorMsg.message)")
                
                DispatchQueue.main.async {
                    self.global.textMsg += "\n\n!!!!!!!!! \(self.ticker) ERROR: \(errorMsg.message)"
                }
                
            } catch {
                Log.Log("\(self.ticker) websocket feed error: \(error)")
                Log.Log("\(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        
    }
}
