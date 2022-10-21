//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI
import Combine

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .center) {
                    SupertabLogo()
                        .frame(height: 50)
                        .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
                NavigationLink(destination: {
                    MemoryGameView()
                        .padding()
                        .navigationTitle("Pay for Access")
                }) {
                    Text("Pay for Access")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
