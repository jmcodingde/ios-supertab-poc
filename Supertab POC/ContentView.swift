//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI
import Combine

struct ContentView: View {
    var authSession = OAuth2PKCESession(
        authorizeUrl: "https://auth.sbx.laterpay.net/oauth2/auth",
        logoutUrl: "https://signon.sbx.supertab.co/oauth2/logout",
        tokenUrl: "https://auth.sbx.laterpay.net/oauth2/token",
        clientId: "client.4d1a76a9-27ba-4ae6-8045-a581af101476",
        redirectUri: "https://e8fe-62-226-109-75.ngrok.io/api/oauth2/callback/supertab-poc",
        callbackURLScheme: "supertab-poc"
    )
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
                }
                Button {
                    Task {
                        do {
                            let response = try await authSession.authenticate()
                            print("Authentication was successful! \(response)")
                        } catch(let error) {
                            print("Authentication failed: \(error)")
                        }
                    }
                } label: {
                    Text("Sign in")
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
