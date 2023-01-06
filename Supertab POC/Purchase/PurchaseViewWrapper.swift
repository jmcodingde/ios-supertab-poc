//
//  PurchaseViewWrapper.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 04.01.23.
//

import SwiftUI

struct PurchaseViewWrapper: View {
    let defaultTitle: String;
    let dismissButtonLabel: String;
    let showCloseButton: Bool
    @ObservedObject var client: TapperClientMachine
    var body: some View {
        PurchaseView(defaultTitle: defaultTitle, dismissButtonLabel: dismissButtonLabel, currentState: client.currentState, tab: client.context.tab, selectedOffering: client.context.selectedOffering, offerings: client.context.offerings, offeringsMetadata: client.context.offeringsMetadata, onSelectOffering: { offering in client.send(.selectOffering(offering)) }, onAddToTab: { offering in client.send(.addToTab(offering)) }, onShowApplePaymentSheet: { client.send(.showApplePayPaymentSheet) }, onDismiss: { client.send(.dismiss) }, showCloseButton: showCloseButton)
    }
}
