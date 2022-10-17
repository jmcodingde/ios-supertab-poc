//
//  ApplePayButton.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 17.10.22.
//

import SwiftUI
import PassKit

struct ApplePayButton: UIViewRepresentable {
        func updateUIView(_ uiView: PKPaymentButton, context: Context) {
    
        }
        func makeUIView(context: Context) -> PKPaymentButton {
            return PKPaymentButton(paymentButtonType: .continue, paymentButtonStyle: .black)
        }
}
struct ApplePayButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
             return ApplePayButton()
        }
}
