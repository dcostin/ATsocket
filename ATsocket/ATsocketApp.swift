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
    
    var textMsg = "Coinbase Advanced Trading Websocket\n"
}
