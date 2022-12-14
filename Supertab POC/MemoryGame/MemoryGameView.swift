//
//  MemoryGameView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import SwiftUI

struct MemoryGameView: View {
    @ObservedObject var game: MemoryGameMachine
    var paused = false
        
    var body: some View {
        VStack {
            Spacer()
            if paused {
                Text("Game paused").font(.largeTitle)
            } else if game.currentState == .won {
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
                        .disabled(card.currentState != .cover)
                    }
                }
                .disabled(game.currentState == .lost)
                .opacity(game.currentState == .lost ? 0.5 : 1)
            }
            Spacer()
        }
    }
}

struct MemoryGameView_Previews: PreviewProvider {
    static var previews: some View {
        Spacer()
        MemoryGameView(game: MemoryGameMachine())
        Spacer()
    }
}
