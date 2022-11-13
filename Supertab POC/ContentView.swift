//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI
import Combine

struct ContentView: View {
    let client = TapperClient()
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .center) {
                    SupertabLogo()
                        .frame(height: 50)
                        .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
                /*NavigationLink(destination: {
                    PayPerGameView()
                        .padding()
                        .navigationTitle("Pay per Game")
                }) {
                    Text("Pay per Game")
                }
                NavigationLink(destination: {
                    PayForAccessView()
                        .padding()
                        .navigationTitle("Pay for Access")
                }) {
                    Text("Pay for Access")
                }*/
                Button {
                    Task {
                        do {
                            let tab = try await client.fetchActiveTab()
                            print("Active tab: \(tab)")
                        } catch(let error) {
                            print("Fetching tabs failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Fetch Tabs")
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
