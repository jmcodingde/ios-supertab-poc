//
//  PayForAccess.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 23.10.22.
//

import SwiftUI

let payForAccessViewOfferings = [
    Offering(offeringId: "poc.ios.pay-for-access.30-seconds", summary: "30 sec", price: Price(amount: 50, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "time_pass", metadata: nil, validTimedelta: "1m"),
    Offering(offeringId: "poc.ios.pay-for-access.1-minute", summary: "1 min", price: Price(amount: 100, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "time_pass", metadata: nil, validTimedelta: "1m"),
    Offering(offeringId: "poc.ios.pay-for-access.2-minutes", summary: "2 min", price: Price(amount: 150, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "time_pass", metadata: nil, validTimedelta: "1m")
]

struct PayForAccessView: View {
    @ObservedObject var client: TapperClientMachine
    @ObservedObject var game: MemoryGameMachine
    @State var secondsLeft = 10
    let timer = Timer.publish(every: 1, tolerance: 200, on: .main, in: .common).autoconnect()
    
    init() {
        let game = MemoryGameMachine()
        self.game = game
        client = TapperClientMachine(
            offerings: payForAccessViewOfferings,
            defaultOffering: payForAccessViewOfferings[0],
            onAddedToTab: { offering in
                guard let validTimeDelta = offering.validTimedelta else {
                    print("Missing validTimeDelta in offering")
                    return
                }
                var numberOfSeconds = Int(validTimeDelta.dropLast()) ?? 0
                if validTimeDelta.hasSuffix("m") {
                    numberOfSeconds *= 60
                }
                //secondsLeft = numberOfSeconds
                print(numberOfSeconds)
            }
        )
    }
    
    var body: some View {
        VStack {
            MemoryGameView(game: game, paused: secondsLeft == 0)
            HStack {
                Button {
                    game.send(.reset)
                } label: {
                    Text("Start a new game")
                }
                .disabled(!game.context.isDirty)
                Spacer()
                Text("\(secondsLeft) seconds left")
            }
            Spacer()
        }
        .disabled(secondsLeft == 0)
        .opacity(secondsLeft == 0 ? 0.5 : 1)
        .padding()
        .sheet(isPresented: $client.shouldShowSheet, onDismiss: {
            if secondsLeft > 0 {
                client.send(.dismiss)
            } else {
                client.send(.startPurchase)
            }
        }) {
            PurchaseView(
                defaultTitle: "Want to continue playing?",
                client: client
            )
            .padding(.top, 10)
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
        }
        .onReceive(timer) { time in
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                if client.currentState == .idle {
                    client.send(.startPurchase)
                }
            }
        }
    }
}

struct PayForAccessView_Preview: PreviewProvider {
    static var previews: some View {
        PayForAccessView()
    }
}
