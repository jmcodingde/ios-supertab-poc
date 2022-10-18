//
//  MemoryGameView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import SwiftUI

let memoryGameViewOfferings = [
    Offering(50, 1, "1 game"),
    Offering(100, 2, "2 games"),
    Offering(200, 5, "5 games")
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
                game.send(.addGames(offering.numGames))
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
                Text("Start new game" + (game.context.gamesLeft > 0 ? " (\(game.context.gamesLeft) left)" : ""))
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $client.shouldShowSheet, onDismiss: {
            print("Purchase canceled")
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
