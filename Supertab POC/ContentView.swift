//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI
import Combine

struct Tab {
    var amount: Int
    let limit: Int
    let currency: String
}

let defaultOfferings = [
    Offering(50, 1, "1 game"),
    Offering(100, 2, "2 games"),
    Offering(200, 5, "5 games")
]

struct ContentView: View {
    @State var showingTabSheet = false
    @State var tabSheetPresentationDetent = PresentationDetent.height(520)
    @State var tab = Tab(amount: 150, limit: 500, currency: "USD")
    let offerings = defaultOfferings
    @State var selectedOffering: Offering? = defaultOfferings[0]
    @State var isPurchaseDone: Bool = false
    @State var tabSheetTimer: Timer? = nil
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
                    isPurchaseDone = false
                    selectedOffering = defaultOfferings[0]
                    showingTabSheet  = true
                } label: {
                    Text("Show Tab Sheet")
                }
            }
        }
        .sheet(isPresented: $showingTabSheet, onDismiss: {
            print("Purchase canceled")
            tabSheetTimer?.invalidate()
            tabSheetTimer = nil
        }) {
            PurchaseView(
                title: "Want to play another game?",
                onConfirmPurchase: { offering in
                    print("Confirmed purchase of \(offering.description)")
                    if tab.amount >= tab.limit {
                        print("Cannot add purchase to Tab, Tab is full.")
                    } else {
                        selectedOffering = nil
                        withAnimation {
                            tab.amount += offering.amount
                            isPurchaseDone = true
                        }
                        self.tabSheetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                            showingTabSheet = false
                        }
                    }
                },
                onSelectOffering: { offering in
                    print("Selected offering: \(offering.description)")
                    selectedOffering = offering
                },
                offerings: offerings,
                selectedOffering: selectedOffering,
                tab: tab,
                isDone: isPurchaseDone
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
