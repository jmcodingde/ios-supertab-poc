//
//  PayPerGameView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 23.10.22.
//

import SwiftUI

let payPerGameOfferings = [
    Offering(offeringId: "poc.ios.pay-per-game.1-game", summary: "1 game", price: Price(amount: 50, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "single_purchase", metadata: ["numGames": 1], validTimedelta: nil),
    Offering(offeringId: "poc.ios.pay-per-game.2-games", summary: "2 games", price: Price(amount: 100, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "single_purchase", metadata: ["numGames": 2], validTimedelta: nil),
    Offering(offeringId: "poc.ios.pay-per-game.5-games", summary: "5 games", price: Price(amount: 200, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "single_purchase", metadata: ["numGames": 5], validTimedelta: nil)
]

struct PayPerGameView: View {
    @ObservedObject var client: TapperClientMachine
    @ObservedObject var game: MemoryGameMachine
    
    init() {
        let game = MemoryGameMachine(numGames: 0)
        self.game = game
        client = TapperClientMachine(
            offerings: payPerGameOfferings,
            defaultOffering: payPerGameOfferings[0],
            onAddedToTab: { offering in
                game.send(.addGames(offering.metadata!["numGames"]!))
                game.send(.reset)
            }
        )
    }
    
    var body: some View {
        VStack {
            MemoryGameView(game: game)
            Button {
                if game.context.gamesLeft > 0 || game.currentState == .won {
                    game.send(.reset)
                } else {
                    client.send(.startPurchase)
                }
            } label: {
                Text("Start a new game" + (game.context.gamesLeft > 0 ? " (\(game.context.gamesLeft) left)" : ""))
            }
            .disabled(!game.context.isDirty)
            Spacer()
        }
        .padding()
        .sheet(isPresented: $client.shouldShowSheet, onDismiss: {
            client.send(.dismiss)
        }) {
            PurchaseView(
                defaultTitle: "Want to play another game?",
                client: client
            )
                .padding(.top, 10)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct PayPerGameView_Preview: PreviewProvider {
    static var previews: some View {
        PayPerGameView()
    }
}
