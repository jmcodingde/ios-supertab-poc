//
//  PayForAccess.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 23.10.22.
//

import SwiftUI

struct PayForAccessView: View {
    @ObservedObject var client: TapperClientMachine
    @ObservedObject var game = MemoryGameMachine()
    @State var timer = Timer.publish(every: 1, tolerance: 200, on: .main, in: .common).autoconnect()
    @State var secondsLeft: Int = 30
    var outOfTime: Bool {
        secondsLeft <= 0
    }
    
    init(client: TapperClient, siteClientId: String) {
        self.client = TapperClientMachine(
            client: client,
            offeringsMetadata: [
                ["summary": "30 sec"],
                ["summary": "1 min"],
                ["summary": "2 min"]
            ]
        )
        self.client.send(.fetchConfig(siteClientId))
    }
    
    func updateSecondsLeft() {
        if let validTo = client.context.accessValidTo {
            secondsLeft = Int(validTo.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate)
        } else {
            secondsLeft -= 1
        }
        if secondsLeft == 0 && client.currentState == .idle {
            client.send(.startPurchase)
        }
    }
    
    var body: some View {
        VStack {
            MemoryGameView(game: game, paused: outOfTime)
                .disabled(outOfTime)
                .opacity(outOfTime ? 0.5 : 1)
            HStack {
                Button {
                    game.send(.reset)
                } label: {
                    Text("Start a new game")
                }
                .disabled(!game.context.isDirty)
                .disabled(outOfTime)
                .opacity(outOfTime ? 0.5 : 1)
                
                Spacer()
                
                if client.context.isCheckingAccess {
                    Text("Checking access...").opacity(0.5).transition(.opacity)
                }
                else if secondsLeft >= 0 {
                    Text("\(secondsLeft) seconds left").transition(.opacity)
                } else {
                    Button {
                        client.send(.startPurchase)
                    } label: {
                        Text("Continue playing")
                    }
                    .transition(.opacity)
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $client.shouldShowSheet, onDismiss: { client.send(.dismiss) }) {
            PurchaseViewWrapper(
                defaultTitle: "Want to continue playing?",
                dismissButtonLabel: "Continue playing",
                showCloseButton: true,
                client: client
            )
            .presentationDetents([.height(260)])
            //.interactiveDismissDisabled()
            //.presentationDragIndicator(.visible)
        }
        .onChange(of: client.context.isCheckingAccess) { _ in
            updateSecondsLeft()
        }
        .onReceive(timer) { _ in
            updateSecondsLeft()
        }
        .onAppear {
            client.send(.checkAccess)
        }
    }
}

struct PayForAccessView_Preview: PreviewProvider {
    static var previews: some View {
        PayForAccessView(client: TapperClient(), siteClientId: "client.db219fd6-3505-45c8-a44d-4740d28b0e13")
    }
}

