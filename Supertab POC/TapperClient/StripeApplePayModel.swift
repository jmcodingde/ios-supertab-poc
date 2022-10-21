//
//  StripeApplePayModel.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 20.10.22.
//
//  Based on Stripe example code from
//  https://github.com/stripe-samples/accept-a-payment/blob/main/custom-payment-flow/client/ios-swiftui/AcceptAPayment/Model/ApplePayModel.swift

import Foundation
import Stripe
import PassKit

class StripeApplePayModel : NSObject, ObservableObject, STPApplePayContextDelegate {
    
    var clientSecret: String?
    var completionCallback: ((STPPaymentStatus, Error?) -> Void)?
    
    override init() {
        super.init()
    }
    
    func pay(clientSecret: String?, amount: Int, completionCallback: @escaping (STPPaymentStatus, Error?) -> Void) {
        print("Kicking off Stripe Apple Pay payment")
        self.completionCallback = completionCallback
        self.clientSecret = clientSecret
        
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant.de.jmcoding.laterpay.demo", country: "US", currency: "USD")
        paymentRequest.requiredShippingContactFields = []
        paymentRequest.requiredBillingContactFields = []
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Your Tab", amount: NSDecimalNumber(floatLiteral: Double(amount)/100)),
            PKPaymentSummaryItem(label: "Your Tab", amount: NSDecimalNumber(floatLiteral: Double(amount)/100)),
        ]
        
        // Present the Apple Pay Context:
        guard let applePayContext = STPApplePayContext(paymentRequest: paymentRequest, delegate: self) else {
            print("Unable to create Apple Pay Context")
            return
        }
        applePayContext.presentApplePay()
    }

    
    func applePayContext(_ context: StripeApplePay.STPApplePayContext, didCreatePaymentMethod paymentMethod: Stripe.STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping StripeApplePay.STPIntentClientSecretCompletionBlock) {
        guard let clientSecret = self.clientSecret else {
            completion(nil, NSError(domain: "Cannot confirm Stripe Apple Pay payment without client secret", code: 4711))
            return
        }
        print("Completing payment")
        completion(clientSecret, nil);
    }

    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
        print("Apple Pay Payment Sheet completed with status: \(status)")
        completionCallback?(status, error)
    }
}
