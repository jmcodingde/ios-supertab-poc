//
//  PayForAccess.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 23.10.22.
//

import SwiftUI

let payForAccessViewOfferings = [
    Offering(offeringId: "poc.ios.pay-for-access.30-seconds", summary: "30 sec", price: Price(amount: 50, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "time_pass", validTimedelta: "30s"),
    Offering(offeringId: "poc.ios.pay-for-access.1-minute", summary: "1 min", price: Price(amount: 100, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "time_pass", validTimedelta: "1m"),
    Offering(offeringId: "poc.ios.pay-for-access.2-minutes", summary: "2 min", price: Price(amount: 150, currency: "USD"), paymentModel: "pay_merchant_later", salesModel: "time_pass", validTimedelta: "2m")
]

struct PayForAccessView: View {
    @ObservedObject var client = TapperClientMachine(
        offerings: payForAccessViewOfferings,
        defaultOffering: payForAccessViewOfferings[0]
    )
    @ObservedObject var game = MemoryGameMachine()
    @State var timer = Timer.publish(every: 1, tolerance: 200, on: .main, in: .common).autoconnect()
    @State var secondsLeft: Int = 30
    var outOfTime: Bool {
        secondsLeft <= 0
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
                    Text("Checking access...").opacity(0.5)
                }
                else if secondsLeft >= 0 {
                    Text("\(secondsLeft) seconds left")
                } else {
                    Button {
                        client.send(.startPurchase)
                    } label: {
                        Text("Continue playing")
                    }
                }
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $client.shouldShowSheet, onDismiss: { client.send(.dismiss) }) {
            PurchaseView(
                defaultTitle: "Want to continue playing?",
                client: client
            )
            .padding(.top, 10)
            .presentationDetents([.height(520)])
            .presentationDragIndicator(.visible)
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
        PayForAccessView()
    }
}
