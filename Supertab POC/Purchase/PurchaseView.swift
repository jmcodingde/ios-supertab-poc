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
    let offerings: [Offering] = [
        Offering(50, 1, "1 game"),
        Offering(100, 2, "2 games"),
        Offering(200, 5, "5 games")
    ]
    @State var selectedAmount = 50
    @Environment(\.colorScheme) var colorScheme
    var showDetails: Bool = false
    var body: some View {
        VStack {
            Text("Want to play another game?")
                .font(.title2)
                .padding(.top)
                .padding(.bottom)
            HStack {
                ForEach(offerings, id: \.self) { offering in
                    let isSelected = offering.amount == selectedAmount
                    Button {
                        withAnimation {
                            selectedAmount = offering.amount
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
            
            if showDetails {
                HStack {
                    TabIndicatorView(amount: 150, projectedAmount: 150 + selectedAmount, limit: 500, currencyCode: "USD")
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
            }
            
            Spacer()
            
            HStack(alignment: .center) {
                Text("Powered by")
                    .font(.subheadline)
                Image(colorScheme == .light ? "SupertabLogo" : "SupertabLogoLight")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .padding(.vertical)
            }
        }
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseView(showDetails: true)
    }
}
