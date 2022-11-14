//
//  PurchaseView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 16.10.22.
//

import SwiftUI

struct PurchaseView: View {
    let defaultTitle: String;
    @ObservedObject var client: TapperClientMachine
    var title: String {
        switch(client.currentState) {
        case .addingToTab:
            return "..."
        case .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet:
            return "Pay your Tab"
        case .itemAdded, .tabPaid:
            return "Thank you!"
        default:
            return defaultTitle
        }
    }
    var firstParagraph: String {
        switch client.currentState {
        case .fetchingTab:
            return ""
        case .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet:
            return "You've completed your Tab."
        case .tabPaid:
            return "Your Tab has been paid."
        default:
            if let tab = client.context.tab {
                return "You've used **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** of your **\(formattedPrice(amount: tab.limit, currencyCode: tab.currency))** Tab."
            } else {
                return "The Tab makes it easy for you to buy only what you want."
            }
        }
    }
    var secondParagraph: String {
        switch client.currentState {
        case .fetchingTab:
            return ""
        case .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet:
            if let tab = client.context.tab {
                return "Pay your **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** Tab to continue."
            }
        case .tabPaid:
            return "You've used **\(formattedPrice(amount: 0, currencyCode: Tab.defaultCurrency))** of your new **\(formattedPrice(amount: Tab.defaultLimit, currencyCode: Tab.defaultCurrency))** Tab."
        default:
            if let _ = client.context.tab {
                return ""
            } else {
                return "You'll only pay when your Tab reaches \(formattedPrice(amount: Tab.defaultLimit, currencyCode: Tab.defaultCurrency))."
            }
        }
        return ""
    }
    
    var body: some View {
        let tab = client.context.tab
        VStack {
            Text(title)
                .font(.title2)
                .padding(.top)
                .padding(.bottom)
            
            if client.currentState == .showingOfferings || client.currentState == .fetchingTab {
                let isLoading = client.currentState == .fetchingTab
                HStack {
                    ForEach(client.context.offerings.indices, id: \.self) { index in
                        let offering = client.context.offerings[index]
                        let isSelected = offering == client.context.selectedOffering
                        let summary = client.context.offeringsMetadata[index]["summary"] ?? offering.summary
                        Button {
                            client.send(.selectOffering(offering))
                        } label: {
                            VStack {
                                Text("$\(String(format: "%.2f", Float(offering.price.amount)/100.00))")
                                    .bold()
                                    .font(.headline)
                                Text(summary)
                                    .font(.subheadline)
                            }
                            .padding()
                            .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .primary)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: .infinity)
                                    .stroke(Color.primary, lineWidth: 3)
                                    .opacity(isLoading ? 0.4 : 1)
                            )
                            
                        }
                        .background(isSelected ? Color.primary : Color(UIColor.systemBackground))
                        .clipShape(Capsule())
                        
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.opacity)
                .opacity(isLoading ? 0.5 : 1)
                
                Button(action: {
                    if let selectedOffering = client.context.selectedOffering {
                        client.send(.addToTab(selectedOffering))
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
                .transition(.opacity)
                .opacity(isLoading ? 0.5 : 1)
                
                Text("No credit card required")
                    .opacity(0.5)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
            
            HStack(alignment: .center) {
                TabIndicatorView(amount: tab?.total ?? 0, projectedAmount: (tab?.total ?? 0) + (client.context.selectedOffering?.price.amount ?? 0), limit: tab?.limit ?? Tab.defaultLimit, currencyCode: tab?.currency ?? Tab.defaultCurrency, loading: client.currentState == .fetchingTab)
                    .frame(width: 100, height: 120)
                    .padding(.leading)
                    .padding(.vertical)
                    .id("tabIndicator")
                VStack(spacing: 10) {
                    Text(.init(firstParagraph))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("firstParagraph")
                        .transition(.scale)
                    Text(.init(secondParagraph))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id("secondParagraph")
                        .transition(.scale)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary, lineWidth: 2)
                    .opacity(0.2)
                
            )
            .padding(.horizontal)
            .padding(.bottom)
            .zIndex(1)
            
            if [.paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet].contains(client.currentState) {
                Button {
                    client.send(.showApplePayPaymentSheet)
                } label: {
                    Text("")
                }
                .frame(height: 50)
                .buttonStyle(ApplePayButtonStyle())
                .cornerRadius(.infinity)
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(client.currentState != .paymentRequired)
                .opacity(client.currentState == .paymentRequired ? 1 : 0.5)
            }
            
            Spacer()
            
            if client.currentState == .itemAdded || client.currentState == .tabPaid {
                Button {
                    client.send(.dismiss)
                } label: {
                    Text("Dismiss")
                        .foregroundColor(Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.primary.opacity(0.2))
                .cornerRadius(.infinity)
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.opacity)
            }
            
            
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
        PurchaseView(
            defaultTitle: "Want to play another game?",
            client: TapperClientMachine(client: TapperClient())
        )
        .previewDevice(PreviewDevice(rawValue: "iPhone 11"))
    }
}
