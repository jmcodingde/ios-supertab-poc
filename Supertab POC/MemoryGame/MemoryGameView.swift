//
//  MemoryGameView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import SwiftUI

let memoryGameViewOfferings = [
    Offering(offeringId: "memoryGame.1-game", summary: "1 game", price: Price(amount: 500, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "single_purchase", metadata: ["numGames": 1]),
    Offering(offeringId: "memoryGame.2-games", summary: "2 games", price: Price(amount: 100, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "single_purchase", metadata: ["numGames": 2]),
    Offering(offeringId: "memoryGame.5-game2", summary: "5 games", price: Price(amount: 200, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "single_purchase", metadata: ["numGames": 5])
]

struct MemoryGameView: View {
    @ObservedObject var client: TapperClientMachine
    @ObservedObject var game: MemoryGameMachine
    
    init() {
        let game = MemoryGameMachine()
        self.game = game
        client = TapperClientMachine(
            offerings: memoryGameViewOfferings,
            defaultOffering: memoryGameViewOfferings[0],
            onAddedToTab: { offering in
                game.send(.addGames(offering.metadata!["numGames"]!))
                game.send(.reset)
            }
        )
    }
    
    var body: some View {
        VStack {
            Spacer()
            if game.currentState == .won {
                Text("You won! Score: \(game.context.numMismatchesLeft)/\(game.context.allowedNumMismatches)").font(.largeTitle)
            } else if game.currentState == .lost {
                Text("You lost").font(.largeTitle)
            } else {
                Text("Score: \(game.context.numMismatchesLeft)/\(game.context.allowedNumMismatches)").font(.largeTitle)
            }
            Spacer()
            let maxRow = game.context.numRows - 1;
            ForEach((0...maxRow), id: \.self) { currentRow in
                HStack {
                    let maxCol = game.context.numCols - 1;
                    ForEach((0...maxCol), id: \.self) { currentCol in
                        let currentIndex = currentRow * game.context.numCols + currentCol;
                        let card = game.context.cards[currentIndex]
                        MemoryGameCardView(card: card) {
                            print("\nTapped card #\(currentIndex)")
                            game.send(.tapCard(card))
                        }
                    }
                }
            }
            Spacer()
            Button {
                if game.context.gamesLeft > 0 {
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

struct MemoryGameView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryGameView()
    }
}
