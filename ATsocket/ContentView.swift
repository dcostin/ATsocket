//
//  ContentView.swift
//  ATsocket
//
//  Created by Dan Costin on 11/18/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var global = MsgTxt.global
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .padding()
            
            HStack {
                ForEach (global.pairNames, id: \.self) { pairName in
                    VStack {
                        Text(pairName)
                        Text(global.pairValues[pairName]?.usd() ?? "")
                            .font(.system(.body, design: .monospaced))
                        Text(global.heartbeats[pairName] ?? "")
                    }
                    Spacer()
                        .frame(width: 20.0)
                }
            }
        }
        .padding()
        
        ScrollView {
            VStack {
                Text(global.textMsg)
            }
            .padding()
        }
    }
}


#Preview {
    ContentView()
}
