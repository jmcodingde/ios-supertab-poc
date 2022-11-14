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
    @State var clientConfig: TapperClient.ClientConfig?
    @State var activeTab: TapperClient.TabResponse?
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading) {
                    SupertabLogo()
                        .frame(height: 50)
                        .padding(.vertical)
                }
                .frame(maxWidth: .infinity)
                NavigationLink(destination: {
                    PayPerGameView(client: client, siteClientId: "client.d20c6b17-cb04-46df-b94d-5945767ae9bc")
                        .padding()
                        .navigationTitle("Pay per Game")
                }) {
                    Text("Pay per Game")
                }
                NavigationLink(destination: {
                    PayForAccessView(client: client, siteClientId: "client.c8e013f9-86c0-4d36-9a74-381224698c5c")
                        .padding()
                        .navigationTitle("Pay for Access")
                }) {
                    Text("Pay for Access")
                }
            }
        }
        /*.onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    print("Re-authenticating")
                    try await client.authenticate()
                }
            }
        }*/
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
