//
//  TapperClientMachine.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 18.10.22.
//

import Foundation
import SwiftUI
import Stripe

struct CurrentTabResponse: Codable, Equatable {
    let total: Int
    let limit: Int
    let id: String
    let currency: String
    var isFull: Bool {
        total >= limit
    }
    static let defaultLimit = 500
    static let defaultCurrency  = "USD"
}

typealias Tab = CurrentTabResponse

struct PurchaseResponse: Codable {
    var itemAdded: Bool
    var paymentItentId: String?
    var tab: CurrentTabResponse
}

struct StartPaymentResponse: Codable, Equatable {
    var clientSecret: String
    var publishableKey: String
    var userToken: String
}

typealias PaymentDetails = StartPaymentResponse

struct Offering: Hashable, Codable {
    let offeringId: String
    let summary: String
    let price: Price
    let paymentModel: String
    let salesModel: String
    let metadata: [String: Int]?
}

struct Price: Hashable, Codable {
    let amount: Int
    let currency: String
}

enum TapperClientState: Equatable {
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

var tapperClientInitialState = TapperClientState.idle

struct TapperClientContext {
    var offerings: [Offering]
    var defaultOffering: Offering?
    var selectedOffering: Offering?
    var tab: Tab?
    var errorMessage: String?
    let apiRoot = "https://ios.poc.laterpay.net/api/laterpay"
    var paymentDetails: PaymentDetails? = nil
    let stripeApplePay = StripeApplePayModel()
}

enum TapperClientEvent: Equatable {
    case startPurchase
    case dismiss
    case fetchTabDone(_ tab: Tab?)
    case fetchTabError(_ message: String)
    case selectOffering(_ offering: Offering)
    case addToTab(_ offering: Offering)
    case addToTabDone(offering: Offering, tab: Tab, itemAdded: Bool)
    case addToTabError(_ message: String)
    case fetchPaymentDetailsDone(paymentDetails: StartPaymentResponse)
    case fetchPaymentDetailsError(_ message: String)
    case showApplePayPaymentSheet
    case applePayCanceled
    case applePayDone
    case applePayError(_ message: String)
    case genericError(_ message: String)
}

enum TapperClientServices {
    static let session = URLSession.shared
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
    static func fetchTab(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        Task.detached {
            do {
                let url = URL(string: "\(context.apiRoot)/current_tab")!
                print("Fetching data from \(url)")
                let (data, rawResponse) = try await session.data(from: url)
                let response = rawResponse as! HTTPURLResponse
                print("Response status code: \(response.statusCode)")
                switch response.statusCode {
                case 200:
                    let tab = try! decoder.decode(CurrentTabResponse.self, from: data)
                    print("Received tab")
                    print(tab)
                    send(.fetchTabDone(tab))
                case 204:
                    print("User has no tab")
                    send(.fetchTabDone(nil))
                default:
                    print("Cannot handle response with status code \(response.statusCode)")
                }
            } catch(let error) {
                send(.fetchTabError(error.localizedDescription))
            }
        }
    }
    static func addToTab(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext, _ event: TapperClientEvent) {
        switch(event) {
        case .addToTab(let offering):
            print("Adding to tab...")
            print(offering)
            
            Task.detached {
                let url = URL(string: "\(context.apiRoot)/purchase")!
                var request = URLRequest(url: url)
                request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                let bodyData = try! encoder.encode(offering)
                request.httpMethod = "POST"
                request.httpBody = bodyData
                //print("Will send request with body:", String(data: request.httpBody!, encoding: .utf8)!)
                //print("Will send request with headers:", request.allHTTPHeaderFields as Any)
                
                let (data, rawResponse) = try await session.data(for: request)
                let response = rawResponse as! HTTPURLResponse
                print("Response status code: \(response.statusCode)")
                switch response.statusCode {
                case 201, 402:
                    let result = try! decoder.decode(PurchaseResponse.self, from: data)
                    print(result)
                    send(.addToTabDone(offering: offering, tab: result.tab, itemAdded: result.itemAdded))
                default:
                    print("Cannot handle response with status code \(response.statusCode)")
                    print(response)
                }
            }
        default:
            send(.addToTabError("Event not supported: \(event)"))
        }
    }
    static func fetchPaymentDetails(_ send: @escaping (TapperClientEvent) -> Void, _ context: TapperClientContext) {
        Task.detached {
            do {
                guard let tab = context.tab else {
                    print("Can not prepare payment without tab")
                    return
                }
                let url = URL(string: "\(context.apiRoot)/payment?tabId=\(tab.id)")!
                var request = URLRequest(url: url)
                request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                
                let (data, rawResponse) = try await session.data(for: request)
                let response = rawResponse as! HTTPURLResponse
                print("Response status code: \(response.statusCode)")
                guard response.statusCode == 200 else {
                    print("Cannot handle response with status code \(response.statusCode)")
                    print(response)
                    return
                }
                let result = try! decoder.decode(StartPaymentResponse.self, from: data)
                print(result)
                send(.fetchPaymentDetailsDone(paymentDetails: result))
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
            TapperClientServices.fetchTab(send, context)
        case (.fetchingTab, .fetchTabDone(let tab)):
            context.tab = tab
            if isTabFull() {
                currentState = .fetchingPaymentDetails
                TapperClientServices.fetchPaymentDetails(send, context)
            } else {
                currentState = .showingOfferings
            }
        case (.showingOfferings, .selectOffering(let selectedOffering)):
            context.selectedOffering = selectedOffering
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
                onAddedToTab?(offering)
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
        case (_, .dismiss):
            currentState = .idle
        case
            (.fetchingTab, .fetchTabError(let message)),
            (.addingToTab, .addToTabError(let message)),
            (.fetchingPaymentDetails, .fetchPaymentDetailsError(let message)),
            (.showingApplePayPaymentSheet, .applePayError(let message)),
            (_, .genericError(let message)):
            context.errorMessage = message
            currentState = .error
        default:
            print("Cannot handle event \(event) in state \(currentState)")
        }
    }
}
