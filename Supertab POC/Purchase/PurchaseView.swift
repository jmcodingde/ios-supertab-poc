//
//  PurchaseView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 16.10.22.
//

import SwiftUI

struct PurchaseView: View {
    let defaultTitle: String;
    let dismissButtonLabel: String
    let currentState: TapperClientState
    let tab: Tab?
    let selectedOffering: Offering?
    let offerings: [Offering]
    let offeringsMetadata: [Metadata]
    let onSelectOffering: (Offering) -> Void
    let onAddToTab: (Offering) -> Void
    let onShowApplePaymentSheet: () -> Void
    let onDismiss: () -> Void
    
    var title: String {
        switch(currentState) {
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
        switch currentState {
        case .fetchingTab:
            return ""
        case .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet:
            return "You've completed your Tab."
        case .tabPaid:
            return "Your Tab has been paid."
        case .itemAdded:
            if let summary = tab?.purchases[0].metadata?["summary"] {
                return "You've added \(summary)"
            } else {
                return "Your purchase has been added"
            }
        default:
            if let tab = tab {
                return "You've used **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** of your **\(formattedPrice(amount: tab.limit, currencyCode: tab.currency))** Tab."
            } else {
                return "The Tab makes it easy for you to buy only what you want."
            }
        }
    }
    var secondParagraph: String {
        switch currentState {
        case .fetchingTab:
            return ""
        case .itemAdded:
            if let tab = tab {
                return "You've used **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** of your **\(formattedPrice(amount: tab.limit, currencyCode: tab.currency))** Tab."
            } else {
                return "The Tab makes it easy for you to buy only what you want."
            }
        case .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet:
            if let tab = tab {
                return "Pay your **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** Tab to continue."
            }
        case .tabPaid:
            return "You've used **\(formattedPrice(amount: 0, currencyCode: Tab.defaultCurrency))** of your new **\(formattedPrice(amount: Tab.defaultLimit, currencyCode: Tab.defaultCurrency))** Tab."
        default:
            if let _ = tab {
                return ""
            } else {
                return "You'll only pay when your Tab reaches \(formattedPrice(amount: Tab.defaultLimit, currencyCode: Tab.defaultCurrency))."
            }
        }
        return ""
    }
    
    var body: some View {
        let tab = tab
        VStack {
            Text(title)
                .font(.title2)
                .padding(.top)
                .padding(.bottom)
            
            if [.showingOfferings, .fetchingTab].contains(currentState) {
                let isLoading = currentState == .fetchingTab
                OfferingsList(offerings: offerings, selectedOffering: selectedOffering, offeringsMetadata: offeringsMetadata, isLoading: isLoading, onSelectOffering: onSelectOffering)
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.opacity)
                .opacity(isLoading ? 0.5 : 1)
                
                Button(action: {
                    if let selectedOffering = selectedOffering {
                        onAddToTab(selectedOffering)
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
            
            if [.addingToTab, .itemAdded, .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet, .tabPaid].contains(currentState) {
                HStack(alignment: .center) {
                    TabIndicatorView(amount: tab?.total ?? 0, projectedAmount: (tab?.total ?? 0) + (selectedOffering?.price.amount ?? 0), limit: tab?.limit ?? Tab.defaultLimit, currencyCode: tab?.currency ?? Tab.defaultCurrency, loading: currentState == .fetchingTab)
                        .frame(width: 90, height: 90)
                        .id("tabIndicator")
                        .padding(.vertical)
                    VStack(spacing: 10) {
                        Text(.init(firstParagraph))
                            .font(.headline)
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
                .padding(.horizontal)
                .padding(.bottom)
            }
            
            if [.paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet].contains(currentState) {
                Button {
                    onShowApplePaymentSheet()
                } label: {
                    Text("")
                }
                .frame(height: 50)
                .buttonStyle(ApplePayButtonStyle())
                .cornerRadius(.infinity)
                .padding(.horizontal)
                .padding(.bottom)
                .disabled(currentState != .paymentRequired)
                .opacity(currentState == .paymentRequired ? 1 : 0.5)
            }
            
            if [.itemAdded, .tabPaid].contains(currentState) {
                Button {
                    onDismiss()
                } label: {
                    Text(dismissButtonLabel)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.primary)
                .cornerRadius(.infinity)
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.opacity)
            }
            
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

struct PurchaseViewPreview: View {
    let defaultTitle = "Want to play another game?"
    let dismissButtonLabel = "Start a new game"
    let currentState: TapperClientState
    let tab = Tab(id: "tab-1", createdAt: Date.now, updatedAt: Date.now, merchantId: "merchant-1", userId: "user-1", status: .open, paidAt: nil, total: 150, limit: 500, currency: .usd, paymentModel: .payLater, purchases: [], metadata: Metadata(), testMode: false, lpUserId: "lp-user-1", guestEmail: nil, tabStatistics: TapperClient.TabStatistics(purchasesCount: 0, purchasesNetAmount: nil, obfuscatedPurchasesCount: 0, obfuscatedPurchasesTotal: 0))
    let offerings = [
        Offering(id: "offering-1", createdAt: Date.now, updatedAt: Date.now, itemTemplateId: "template-1", description: "Description 1", price: Price(amount: 50, currency: .usd), salesModel: .timePass, paymentModel: .payLater, summary: "Offering Summary 1"),
        Offering(id: "offering-2", createdAt: Date.now, updatedAt: Date.now, itemTemplateId: "template-2", description: "Description 2", price: Price(amount: 100, currency: .usd), salesModel: .timePass, paymentModel: .payLater, summary: "Offering Summary 2"),
        Offering(id: "offering-3", createdAt: Date.now, updatedAt: Date.now, itemTemplateId: "template-3", description: "Description 3", price: Price(amount: 200, currency: .usd), salesModel: .timePass, paymentModel: .payLater, summary: "Offering Summary 3")
    ]
    @State var selectedOffering: Offering?
    let metadata = [
        ["summary": "Summary 1"],
        ["summary": "Summary 2"],
        ["summary": "Summary 3"]
    ]
    
    init(currentState: TapperClientState? = nil) {
        self.currentState = currentState ?? TapperClientState.showingOfferings
    }
    
    func onSelectOffering(offering: Offering) -> Void {
        print("onSelectOffering: \(offering)")
        selectedOffering = offering
    }
    func onAddToTab(offering: Offering) -> Void {
        print("onAddToTab: \(offering)")
    }
    func onShowApplePaymentSheet() -> Void {
        print("onShowApplePaymentSheet")
    }
    func onDismiss() -> Void {
        print("onDismiss")
    }
    
    var body: some View {
        PurchaseView(defaultTitle: defaultTitle, dismissButtonLabel: dismissButtonLabel, currentState: currentState, tab: tab, selectedOffering: selectedOffering ?? offerings[0], offerings: offerings, offeringsMetadata: metadata, onSelectOffering: onSelectOffering, onAddToTab: onAddToTab, onShowApplePaymentSheet: onShowApplePaymentSheet, onDismiss: onDismiss)
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseViewPreview(currentState: .fetchingTab).previewDisplayName("fetchingTab")
        PurchaseViewPreview(currentState: .showingOfferings).previewDisplayName("showingOfferings")
        PurchaseViewPreview(currentState: .addingToTab).previewDisplayName("addingToTab")
        PurchaseViewPreview(currentState: .itemAdded).previewDisplayName("itemAdded")
    }
}
