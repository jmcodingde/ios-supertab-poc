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
    let showCloseButton: Bool
    
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
            return "You've completed your Tab"
        case .tabPaid:
            return "Your Tab has been paid"
        case .addingToTab:
            return "..."
        case .itemAdded:
            if tab?.purchases.count ?? 0 > 0 {
                if let summary = tab?.purchases[0].metadata?["summary"] {
                    return "You've added \(summary)"
                }
            }
            return "Your purchase has been added"
        default:
            if let tab = tab {
                return "You've used **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** of your **\(formattedPrice(amount: tab.limit, currencyCode: tab.currency))** Tab."
            } else {
                return "The Tab makes it easy for you to buy only what you want"
            }
        }
    }
    var secondParagraph: String {
        switch currentState {
        case .fetchingTab:
            return ""
        case .addingToTab, .itemAdded:
            if let tab = tab {
                return "You've used **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** of your **\(formattedPrice(amount: tab.limit, currencyCode: tab.currency))** Tab"
            } else {
                return "The Tab makes it easy for you to buy only what you want"
            }
        case .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet:
            if let tab = tab {
                return "Pay your **\(formattedPrice(amount: tab.total, currencyCode: tab.currency))** Tab to continue"
            }
        case .tabPaid:
            return "You've used **\(formattedPrice(amount: 0, currencyCode: Tab.defaultCurrency))** of your new **\(formattedPrice(amount: Tab.defaultLimit, currencyCode: Tab.defaultCurrency))**\u{00a0}Tab"
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
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(title)
                    .font(.custom("Helvetica Neue Bold", size: 18))
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .padding(.leading, showCloseButton ? 17 : 0)
                Spacer()
                if showCloseButton {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark").foregroundColor(.primary).opacity(0.6)
                            .frame(width: 17, height: 17)
                    }
                }
            }
            .padding(.top, 26.46)
            .padding(.horizontal, 20)
            
            if [.showingOfferings, .fetchingTab].contains(currentState) {
                let isLoading = currentState == .fetchingTab
                OfferingsList(offerings: offerings, selectedOffering: selectedOffering, offeringsMetadata: offeringsMetadata, isLoading: isLoading, onSelectOffering: onSelectOffering)
                .padding(.horizontal)
                .padding(.top, 26.46)
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
                        .font(.custom("Helvetica Neue Bold", size: 16))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .tracking(-0.16)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52.82)
                }
                .background(Color.primary)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.top, 15.6)
                .transition(.opacity)
                .opacity(isLoading ? 0.5 : 1)
                
                //No credit card required
                Text("No credit card required").font(.custom("Helvetica Neue Regular", size: 14)).tracking(0.14).lineSpacing(10).multilineTextAlignment(.center)
                    .opacity(0.6)
                    .padding(.horizontal)
                    .padding(.top, 17)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            }
            
            if [.addingToTab, .itemAdded, .paymentRequired, .fetchingPaymentDetails, .showingApplePayPaymentSheet, .tabPaid].contains(currentState) {
                HStack(alignment: .center, spacing: 20) {
                    TabIndicatorView(amount: tab?.total ?? 0, projectedAmount: (tab?.total ?? 0) + (selectedOffering?.price.amount ?? 0), limit: tab?.limit ?? Tab.defaultLimit, currencyCode: tab?.currency ?? Tab.defaultCurrency, loading: currentState == .fetchingTab)
                        .frame(width: 70, height: 70)
                        .id("tabIndicator")
                    VStack(spacing: 10) {
                        Text(.init(firstParagraph))
                            .font(.custom("Helvetica Neue Medium", size: 16))
                            .lineSpacing(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("firstParagraph")
                            //.transition(.scale)
                        Text(.init(secondParagraph))
                            .font(.custom("Helvetica Neue", size: 14))
                            .opacity(0.6)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("secondParagraph")
                            //.transition(.scale)
                    }
                    .frame(height: 90)
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
                        .font(.custom("Helvetica Neue Bold", size: 16))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .tracking(-0.16)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52.82)
                }
                .background(Color.primary)
                .cornerRadius(.infinity)
                .padding(.horizontal)
                .padding(.bottom)
                .transition(.opacity)
            }

            Spacer()
            
            /*HStack(alignment: .center) {
                Text("Powered by")
                    .font(.subheadline)
                SupertabLogo()
                    .frame(height: 20)
                    .padding(.vertical)
            }*/
        
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
    
    @State var isPresented = true
    
    var body: some View {
        HStack {}
            .sheet(isPresented: $isPresented) {
                PurchaseView(defaultTitle: defaultTitle, dismissButtonLabel: dismissButtonLabel, currentState: currentState, tab: tab, selectedOffering: selectedOffering ?? offerings[0], offerings: offerings, offeringsMetadata: metadata, onSelectOffering: onSelectOffering, onAddToTab: onAddToTab, onShowApplePaymentSheet: onShowApplePaymentSheet, onDismiss: onDismiss, showCloseButton: true)
                    .padding(.top, 10)
                    .presentationDetents([.height(260)])
                    .interactiveDismissDisabled()
                    //.presentationDragIndicator(.visible)
            }
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseViewPreview(currentState: .fetchingTab).previewDisplayName("fetchingTab")
        PurchaseViewPreview(currentState: .showingOfferings).previewDisplayName("showingOfferings")
        PurchaseViewPreview(currentState: .addingToTab).previewDisplayName("addingToTab")
        PurchaseViewPreview(currentState: .itemAdded).previewDisplayName("itemAdded")
        PurchaseViewPreview(currentState: .tabPaid).previewDisplayName("tabPaid")
    }
}
