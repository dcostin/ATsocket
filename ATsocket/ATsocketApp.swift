//
//  ATsocketApp.swift
//  ATsocket
//
//  Created by Dan Costin on 11/18/23.
//

import SwiftUI



@main
struct ATsocketApp: App {
    
    var latestPrice = 0.0
    
    var websockets = [ CoinbaseATSocket(ticker: "BTC-USD"),
                       CoinbaseATSocket(ticker: "ETH-USD"),
                       CoinbaseATSocket(ticker: "LTC-USD"),
                       CoinbaseATSocket(ticker: "SOL-USD"),
                       CoinbaseATSocket(ticker: "DOGE-USD"),
                       ]
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class MsgTxt: ObservableObject {
    static let global = MsgTxt()
    
    @Published var textMsg = "Coinbase Advanced Trading Websocket\n"
    @Published var pairNames : [ String ] = []
    @Published var pairValues : [String : Double] = [:]
    @Published var timestamps : [String : String] = [:]
    @Published var heartbeats : [String : String] = [:]
}

extension Double {
    func usd(_ n: Int = -1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = (n == -1 ? (self < 1 ? 5 : 2) : n)
        return formatter.string(for: self) ?? "$0.00"
    }
}
