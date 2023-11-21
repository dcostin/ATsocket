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
    
    var websocket = CoinbaseATSocket()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class MsgTxt: ObservableObject {
    static let global = MsgTxt()
    
    @Published var textMsg = "Coinbase Advanced Trading Websocket\n"
    @Published var pairName = "UNK/UNK"
    @Published var pairValue = 0.0
    @Published var timestamp = "---"
}

extension Double {
    func usd(_ n: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = n
        return formatter.string(for: self) ?? "$0.00"
    }
}
