//
//  TapperClientMachine.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 18.10.22.
//

import Foundation
import Stripe
import SwiftUI

enum TapperClientState: Equatable {
    case noConfig
    case fetchingConfig
    case idle
    case fetchingTab
    case showingOfferings
    case addingToTab
    case itemAdded
    case fetchingPaymentDetails
    case paymentRequired
    case showingApplePayPaymentSheet
    case tabPaid
    case error
}

var tapperClientInitialState = TapperClientState.noConfig

typealias Offering = TapperClient.SiteOffering
typealias Tab = TapperClient.TabResponse
typealias PaymentDetails = TapperClient.PaymentStartResponse
typealias AccessResponse = TapperClient.AccessResponse
typealias SiteContentKey = TapperClient.SiteContentKey
typealias Purchase = TapperClient.PurchaseResponse
typealias Metadata = TapperClient.Metadata
typealias Price = TapperClient.Price
typealias ClientConfig = TapperClient.ClientConfig

struct TapperClientContext {
    var offerings: [Offering] = []
    var offeringsMetadata: [Metadata]
    var defaultOffering: Offering?
    var selectedOffering: Offering?
    var lastOfferingAddedToTab: Offering?
    var tab: Tab?
    var errorMessage: String?
    var paymentDetails: PaymentDetails? = nil
    let stripeApplePay = StripeApplePayModel()
    var accessValidTo: Date? = nil
    var isCheckingAccess = false
    var client: TapperClient
    var contentKeys: [SiteContentKey] = []
}

enum TapperClientEvent: Equatable {
    case fetchConfig(_ clientId: String)
    case fetchConfigDone(_ config: ClientConfig)
    case fetchConfigError(_ message: String)
    case startPurchase
    case dismiss
    case fetchTabDone(_ tab: Tab?)
    case fetchTabError(_ message: String)
    case selectOffering(_ offering: Offering)
    case addToTab(_ offering: Offering)
    case addToTabDone(offering: Offering, tab: Tab, itemAdded: Bool)
    case addToTabError(_ message: String)
    case fetchPaymentDetailsDone(paymentDetails: PaymentDetails)
    case fetchPaymentDetailsError(_ message: String)
    case showApplePayPaymentSheet
    case applePayCanceled
    case applePayDone
    case applePayError(_ message: String)
    case genericError(_ message: String)
    case checkAccess
    case checkAccessDone(validTo: Date?)
    case checkAccessError(_ message: String)
}

enum TapperClientServices {
    static func fetchConfig(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext, _ event: TapperClientEvent) {
        switch event {
        case .fetchConfig(let clientId):
            Task {
                do {
                    let config = try await context.client.fetchClientConfigFor(clientId: clientId)
                    print("Received config")
                    print(config)
                    send(.fetchConfigDone(config))
                } catch(let error) {
                    send(.fetchConfigError(error.localizedDescription))
                }
            }
        default:
            send(.addToTabError("Event not supported: \(event)"))
        }
    }
    static func fetchTab(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        Task {
            do {
                let activeTab = try await context.client.fetchActiveTab()?.simpleTabResponse
                if let activeTab = activeTab {
                    print("Received tab")
                    print(activeTab)
                    send(.fetchTabDone(activeTab))
                } else {
                    print("User has no tab")
                    send(.fetchTabDone(nil))
                }
            } catch(let error) {
                send(.fetchTabError(error.localizedDescription))
            }
        }
    }
    static func addToTab(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext, _ event: TapperClientEvent) {
        switch(event) {
        case .addToTab(let offering):
            print("Adding to tab: \(offering)")
            
            Task {
                do {
                    let offeringIndex = context.offerings.firstIndex(of: offering)!
                    let metadata: Metadata? = context.offeringsMetadata.count > offeringIndex ? context.offeringsMetadata[offeringIndex] : nil
                    let purchaseResponse = try await context.client.purchase(itemOfferingId: offering.id, metadata: metadata)
                    print("Received purchase response")
                    print(purchaseResponse)
                    send(.addToTabDone(offering: offering, tab: purchaseResponse.tab, itemAdded: purchaseResponse.detail.itemAdded))
                } catch(let error) {
                    send(.addToTabError(error.localizedDescription))
                }
            }
        default:
            send(.addToTabError("Event not supported: \(event)"))
        }
    }
    static func fetchPaymentDetails(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        Task {
            do {
                guard let tab = context.tab else {
                    print("Can not prepare payment without tab")
                    return
                }
                let paymentDetails = try await context.client.startPaymentFor(tabId: tab.id)
                print(paymentDetails)
                send(.fetchPaymentDetailsDone(paymentDetails: paymentDetails))
            } catch(let error) {
                send(.fetchPaymentDetailsError(error.localizedDescription))
            }
        }
    }
    static func applePay(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        print("Starting payment with Apple Pay")
        guard let tab = context.tab else {
            send(.applePayError("Cannot pay with Apple Pay without a tab"))
            return
        }
        guard let paymentDetails = context.paymentDetails else {
            send(.applePayError("Cannot pay with Apple Pay without payment details"))
            return
        }
        StripeAPI.defaultPublishableKey = paymentDetails.publishableKey
        context.stripeApplePay.pay(clientSecret: paymentDetails.clientSecret, amount: tab.total) { status, error in
            print("Handling Stripe Apple Pay completion")
            switch status {
            case .success:
                send(.applePayDone)
            case .userCancellation:
                send(.applePayCanceled)
            case .error:
                send(.applePayError(error?.localizedDescription ?? "Apple Pay error"))
                return
            default:
                send(.applePayError("Apple Pay error"))
            }
        }
        
    }
    static func checkAccess(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        @Sendable func checkAccessForSingle(contentKey: String) async throws -> AccessResponse{
            return try await context.client.checkAccessTo(contentKey: contentKey)
        }
        print("Checking access")
        Task {
            do {
                let accessResponses = try await context.contentKeys
                    .map { $0.contentKey }
                    .concurrentMap { contentKey in
                        try await checkAccessForSingle(contentKey: contentKey)
                    }
                let validTo = accessResponses
                    .filter { $0.access?.status == .granted }
                    .sorted { $0.access!.validTo > $1.access!.validTo }
                    .first?.access!.validTo
                print("Received all access reponses: \(accessResponses)")
                send(.checkAccessDone(validTo: validTo))
            } catch(let error) {
                send(.checkAccessError(error.localizedDescription))
            }
        }
    }
}

enum TapperClientActions {
}

enum TapperClientGurads {
}

class TapperClientMachine: ObservableObject {
    @Published var shouldShowSheet = false {
        didSet {
            if !shouldShowSheet {
                send(.dismiss)
            }
        }
    }
    @Published private(set) var currentState: TapperClientState {
        didSet {
            // Check if the value will change in order to avoid an infinite loop
            let check = ![.idle, .fetchingConfig, .error].contains(currentState)
            if shouldShowSheet != check {
                shouldShowSheet = check
            }
        }
    }
    @Published private(set) var context: TapperClientContext
    let onAddedToTab: ((_ purchase: Purchase) -> Void)?
    
    init(client: TapperClient, offeringsMetadata: [Metadata] = [], onAddedToTab: ((_ purchase: Purchase) -> Void)? = nil) {
        currentState = tapperClientInitialState
        context = TapperClientContext(offeringsMetadata: offeringsMetadata, client: client)
        self.onAddedToTab = onAddedToTab
    }
    
    func isTabFull() -> Bool {
        if let tab = context.tab {
            return tab.status == .full
        } else {
            return false
        }
    }
    
    func send(_ event: TapperClientEvent) {
        DispatchQueue.main.async {
            withAnimation {
                self._send(event)
            }
        }
    }
    
    private func _send(_ event: TapperClientEvent) {
        print("currentState: \(currentState)")
        print("event: \(event)")
        switch(currentState, event) {
        case (.noConfig, .fetchConfig):
            currentState = .fetchingConfig
            TapperClientServices.fetchConfig(send, context, event)
        case (.fetchingConfig, .fetchConfigDone(let config)):
            context.offerings = config.offerings.sorted { $0.price.amount < $1.price.amount }
            context.defaultOffering = config.offerings[0]
            context.contentKeys = config.contentKeys
            currentState = .idle
            send(.checkAccess)
        case (.idle, .startPurchase):
            context.selectedOffering = context.defaultOffering
            currentState = .fetchingTab
            TapperClientServices.fetchTab(send, context)
        case (.fetchingTab, .fetchTabDone(let tab)):
            context.tab = tab
            if isTabFull() {
                currentState = .fetchingPaymentDetails
                TapperClientServices.fetchPaymentDetails(send, context)
            } else {
                currentState = .showingOfferings
            }
        case (.showingOfferings, .selectOffering(let offering)):
            context.selectedOffering = offering
        case (.showingOfferings, .addToTab):
            currentState = .addingToTab
            TapperClientServices.addToTab(send, context, event)
        case (.addingToTab, .addToTabDone(let offering, let tab, let itemAdded)):
            context.tab = tab
            context.selectedOffering = nil
            if isTabFull() {
                currentState = .fetchingPaymentDetails
                TapperClientServices.fetchPaymentDetails(send, context)
            } else {
                currentState = .itemAdded
            }
            if itemAdded {
                context.lastOfferingAddedToTab = offering
                onAddedToTab?(context.tab!.purchases.last!)
                send(.checkAccess)
            }
        case (.fetchingPaymentDetails, .fetchPaymentDetailsDone(let paymentDetails)):
            context.paymentDetails = paymentDetails
            currentState = .paymentRequired
        case (.paymentRequired, .showApplePayPaymentSheet):
            currentState = .showingApplePayPaymentSheet
            TapperClientServices.applePay(send, context)
        case (.showingApplePayPaymentSheet, .applePayCanceled):
            currentState = .paymentRequired
        case (.showingApplePayPaymentSheet, .applePayDone):
            context.tab = nil
            context.selectedOffering = nil
            currentState = .tabPaid
            send(.checkAccess)
        case (_, .dismiss):
            currentState = .idle
        case
            (_, .checkAccessError(let message)):
            context.isCheckingAccess = false
            context.errorMessage = message
            shouldShowSheet = false
            currentState = .error
        case
            (.fetchingConfig, .fetchConfigError(let message)),
            (.fetchingTab, .fetchTabError(let message)),
            (.addingToTab, .addToTabError(let message)),
            (.fetchingPaymentDetails, .fetchPaymentDetailsError(let message)),
            (.showingApplePayPaymentSheet, .applePayError(let message)),
            (_, .genericError(let message)):
            context.errorMessage = message
            shouldShowSheet = false
            currentState = .error
        case (_, .checkAccess):
            if !context.isCheckingAccess {
                context.isCheckingAccess = true
                TapperClientServices.checkAccess(send, context)
            }
        case (_, .checkAccessDone(let validTo)):
            context.isCheckingAccess = false
            context.accessValidTo = validTo
        default:
            print("Cannot handle event \(event) in state \(currentState)")
        }
    }
}
