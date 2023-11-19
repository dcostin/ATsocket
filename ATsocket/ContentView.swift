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
            Text(global.textMsg)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
