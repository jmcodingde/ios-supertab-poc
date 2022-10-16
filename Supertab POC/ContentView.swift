//
//  ContentView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI

struct ContentView: View {
    @State var showingTabSheet = false
    @State var tabSheetPresentationDetent = PresentationDetent.medium
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading) {
                    Image("SupertabLogo").resizable().scaledToFit().frame(height: 40).padding(.vertical)
                    Text("Mobile Integration POC").font(.subheadline).padding(.bottom)
                }
                NavigationLink(destination: {
                    MemoryGameView()
                        .padding()
                        .navigationTitle("Pay for Access")
                }) {
                    Text("Pay for Access")
                }
                Button {
                    showingTabSheet  = true
                } label: {
                    Text("Show Tab Sheet")
                }
            }
        }
        .sheet(isPresented: $showingTabSheet) {
            PurchaseView(showDetails: true)
                .padding(.top, 10)
                .presentationDetents([.height(520)], selection: $tabSheetPresentationDetent)
                .presentationDragIndicator(.visible)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
