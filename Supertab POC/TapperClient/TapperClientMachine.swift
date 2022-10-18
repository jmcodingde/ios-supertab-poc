//
//  TapperClientMachine.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 18.10.22.
//

import Foundation
import SwiftUI

struct Tab: Equatable {
    var amount: Int
    var limit: Int
    var currency: String
    var isFull: Bool {
        amount >= limit
    }
    static let defaultLimit = 500
    static let defaultCurrency  = "usd"
    init(amount: Int, limit: Int, currency: String) {
        self.amount = amount
        self.limit = limit
        self.currency = currency
    }
    init() {
        self.amount = 0
        self.limit = Tab.defaultLimit
        self.currency = Tab.defaultCurrency
    }
}

var globalTab: Tab?

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

enum TapperClientState: Equatable {
    case idle
    case fetchingTab
    case showingOfferings
    case addingToTab
    case itemAdded
    case paymentRequired
    case fetchingPaymentDetails
    case showingApplePayPaymentSheet
    case confirmingPayment
    case tabPaid
    case error
}

var tapperClientInitialState = TapperClientState.idle

struct TapperClientContext {
    var offerings: [Offering]
    var defaultOffering: Offering?
    var selectedOffering: Offering?
    var tab: Tab?
    var errorMessage: String?
}

enum TapperClientEvent: Equatable {
    case startPurchase
    case dismiss
    case fetchTabDone(_ tab: Tab?)
    case fetchTabError(_ message: String)
    case selectOffering(_ offering: Offering)
    case addToTab(_ offering: Offering)
    case addToTabDone(offering: Offering, tab: Tab)
    case addToTabError(_ message: String)
    case startPayment
    case fetchPaymentDetailsDone
    case fetchPaymentDetailsError(_ message: String)
    case showApplePayPaymentSheet
    case confirmPaymentWithApplePay
    case confirmPaymentWithApplePayDone
    case confirmPaymentWithApplePayError(_ message: String)
}

enum TapperClientServices {
    static func fetchTab(_ send: @escaping (TapperClientEvent) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            send(.fetchTabDone(globalTab))
        }
    }
    static func addToTab(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext, _ event: TapperClientEvent) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            switch(event) {
            case .addToTab(let offering):
                var newTab: Tab
                if let tab = context.tab {
                    newTab = tab
                } else {
                    newTab = Tab()
                }
                newTab.amount += offering.amount
                globalTab = newTab
                send(.addToTabDone(offering: offering, tab: newTab))
            default:
                send(.addToTabError("Event not supported: \(event)"))
            }
        }
    }
    static func fetchPaymentDetails(_ send: @escaping (TapperClientEvent) -> Void) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            send(.fetchPaymentDetailsDone)
        }
    }
    static func confirmPaymentWithApplePay(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            send(.confirmPaymentWithApplePayDone)
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
            if shouldShowSheet != (currentState != .idle) {
                shouldShowSheet = currentState != .idle
            }
        }
    }
    @Published private(set) var context: TapperClientContext
    let onAddedToTab: ((_ offering: Offering) -> Void)?
    
    init(offerings: [Offering], defaultOffering: Offering?, onAddedToTab: ((_ offering: Offering) -> Void)? = nil) {
        currentState = tapperClientInitialState
        context = TapperClientContext(offerings: offerings, defaultOffering: defaultOffering)
        self.onAddedToTab = onAddedToTab
    }
    
    func isTabFull() -> Bool {
        if let tab = context.tab {
            return tab.isFull
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
        case (.idle, .startPurchase):
            context.selectedOffering = context.defaultOffering
            currentState = .fetchingTab
            TapperClientServices.fetchTab(send)
        case (.fetchingTab, .fetchTabDone(let tab)):
            context.tab = tab
            currentState = isTabFull()
            ? .paymentRequired
            : .showingOfferings
        case (.showingOfferings, .selectOffering(let selectedOffering)):
            context.selectedOffering = selectedOffering
        case (.showingOfferings, .addToTab):
            currentState = .addingToTab
            TapperClientServices.addToTab(send, context, event)
        case (.addingToTab, .addToTabDone(let offering, let tab)):
            context.tab = tab
            context.selectedOffering = nil
            currentState = isTabFull()
            ? .paymentRequired
            : .itemAdded
            onAddedToTab?(offering)
        case (.paymentRequired, .startPayment):
            currentState = .fetchingPaymentDetails
            TapperClientServices.fetchPaymentDetails(send)
        case (.fetchingPaymentDetails, .fetchPaymentDetailsDone):
            currentState = .confirmingPayment
            TapperClientServices.confirmPaymentWithApplePay(send, context)
        case (.confirmingPayment, .confirmPaymentWithApplePayDone):
            context.tab = nil
            globalTab = nil
            currentState = .tabPaid
        case (_, .dismiss):
            currentState = .idle
        case
            (.fetchingTab, .fetchTabError(let message)),
            (.addingToTab, .addToTabError(let message)),
            (.fetchingPaymentDetails, .fetchPaymentDetailsError(let message)),
            (.confirmingPayment, .confirmPaymentWithApplePayError(let message)):
            context.errorMessage = message
            currentState = .error
        default:
            print("Cannot handle event \(event) in state \(currentState)")
        }
    }
}
