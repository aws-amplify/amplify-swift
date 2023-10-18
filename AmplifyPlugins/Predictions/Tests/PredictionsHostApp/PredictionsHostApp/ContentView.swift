//
//  ContentView.swift
//  PredictionsHostApp
//
//  Created by Saultz, Ian on 11/3/22.
//

import SwiftUI
import Amplify

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("foobar")
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
