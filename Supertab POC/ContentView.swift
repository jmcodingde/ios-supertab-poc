//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI
import Combine

let defaultOfferings = [
    Offering(50, 1, "1 game"),
    Offering(100, 2, "2 games"),
    Offering(200, 5, "5 games")
]

struct ContentView: View {
    @State var tabSheetPresentationDetent = PresentationDetent.height(520)
    @ObservedObject var client = TapperClientMachine(offerings: defaultOfferings, defaultOffering: defaultOfferings[0])
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading) {
                    SupertabLogo()
                        .frame(height: 40)
                        .padding(.vertical)
                    Text("Mobile Integration POC")
                        .font(.subheadline)
                        .padding(.bottom)
                }
                NavigationLink(destination: {
                    MemoryGameView()
                        .padding()
                        .navigationTitle("Pay for Access")
                }) {
                    Text("Pay for Access")
                }
                Button {
                    client.send(.startPurchase)
                } label: {
                    Text("Show Tab Sheet")
                }
            }
        }
        .sheet(isPresented: $client.shouldShowSheet, onDismiss: {
            print("Purchase canceled")
            client.send(.dismiss)
        }) {
            PurchaseView(
                defaultTitle: "Want to play another game?",
                client: client
            )
                .padding(.top, 10)
                .presentationDetents([tabSheetPresentationDetent], selection: $tabSheetPresentationDetent)
                .presentationDragIndicator(.visible)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
