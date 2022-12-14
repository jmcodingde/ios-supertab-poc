//
//  PayPerGameView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 23.10.22.
//

import SwiftUI

struct PayPerGameView: View {
    @ObservedObject var client: TapperClientMachine
    @ObservedObject var game: MemoryGameMachine
    
    init(client: TapperClient, siteClientId: String) {
        let game = MemoryGameMachine(numGames: 0)
        self.game = game
        self.client = TapperClientMachine(
            client: client,
            offeringsMetadata: [
                ["numGames": "1", "summary": "1 game"],
                ["numGames": "2", "summary": "2 games"],
                ["numGames": "5", "summary": "5 games"]
            ],
            onAddedToTab: { purchase in
                print("This purchase was just made: \(purchase)")
                game.send(.addGames(Int(purchase.metadata!["numGames"]!)!))
                game.send(.reset)
            }
        )
        self.client.send(.fetchConfig(siteClientId))
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
            PurchaseViewWrapper(
                defaultTitle: "Want to play another game?",
                dismissButtonLabel: "Start a new game",
                showCloseButton: true,
                client: client
            )
                .presentationDetents([.height(260)])
                //.interactiveDismissDisabled()
                //.presentationDragIndicator(.visible)
        }
    }
}

struct PayPerGameView_Preview: PreviewProvider {
    static var previews: some View {
        PayPerGameView(client: TapperClient(), siteClientId: "client.d30c4a23-35ab-468b-b000-84b5c9e1d283")
    }
}
