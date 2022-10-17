//
//  PurchaseView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 16.10.22.
//

import SwiftUI

struct Offering: Hashable {
    let amount: Int
    let numGames: Int
    let description: String
    init(_ amount: Int, _ numGames: Int, _ description: String) {
        self.amount = amount
        self.numGames = numGames
        self.description = description
    }
}

struct PurchaseView: View {
    let title: String;
    let onConfirmPurchase: (Offering) -> Void
    let onSelectOffering: (Offering) -> Void
    let offerings: [Offering];
    let selectedOffering: Offering?
    let tab: Tab
    var isDone: Bool = true
    
    
    var body: some View {
        VStack {
            Text(isDone ? "Thank you!" : title)
                .font(.title2)
                .padding(.top)
                .padding(.bottom)
            
            if !isDone {
                HStack {
                    ForEach(offerings, id: \.self) { offering in
                        let isSelected = offering == selectedOffering
                        Button {
                            withAnimation {
                                onSelectOffering(offering)
                            }
                        } label: {
                            VStack {
                                Text("$\(String(format: "%.2f", Float(offering.amount)/100.00))")
                                    .bold()
                                    .font(.headline)
                                Text(offering.description)
                                    .font(.subheadline)
                            }
                            .padding()
                            .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .primary)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: .infinity)
                                    .stroke(Color.primary, lineWidth: 3)
                            )
                            
                        }
                        .background(isSelected ? Color.primary : Color(UIColor.systemBackground))
                        .clipShape(Capsule())
                        
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Button(action: {
                    if let selectedOffering = selectedOffering {
                        onConfirmPurchase(selectedOffering)
                    } else {
                        print("Cannot confirm purchase, no offering selected")
                    }
                }) {
                    Text("Put it on my Tab")
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.primary)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.bottom)
                
                Text("No credit card required")
                    .opacity(0.5)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
                
            HStack {
                TabIndicatorView(amount: tab.amount, projectedAmount: tab.amount + (selectedOffering?.amount ?? 0), limit: tab.limit, currencyCode: tab.currency)
                    .frame(width: 100, height: 100)
                    .padding(.leading)
                    .padding(.vertical)
                VStack(alignment: .leading) {
                    Text("The Tab makes it easy for you to buy only what you want.")
                        .padding(.bottom, 1)
                    Text("You'll only pay when your Tab reaches $5.")
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius:10)
                    .stroke(Color.primary, lineWidth: 2)
                    .opacity(0.2)
            )
            .padding(.horizontal)
            .padding(.bottom)
            
            Spacer()
            
            HStack(alignment: .center) {
                Text("Powered by")
                    .font(.subheadline)
                SupertabLogo()
                    .frame(height: 20)
                    .padding(.vertical)
            }
        }
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        let offerings = [
            Offering(50, 1, "1 game"),
            Offering(100, 2, "2 games"),
            Offering(200, 5, "5 games")
        ]
        PurchaseView(
            title: "Want to play another game?",
            onConfirmPurchase: { _ in },
            onSelectOffering: { _ in },
            offerings: offerings,
            selectedOffering: nil,
            tab: Tab(amount: 150, limit: 500, currency: "USD")
        )
    }
}
