//
//  Schema.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 13.11.22.
//

import Foundation

extension TapperClient {
    
    // MARK: Request GET /v1/tabs
    
    struct PaginatedTabRequestParams: Encodable {
        var status: TabStatus?
        var paymentModel: PaymentModel?
        var currency: Currency?
        var isActive: Bool?
        var limit: Int?
        var cursor: Int?
    }
    
    class PaginatedTabRequest: GetRequest {
        init(baseUrl: URL, params: PaginatedTabRequestParams, accessToken: String) {
            super.init(path: "/v1/tabs", baseUrl: baseUrl, params: params, accessToken: accessToken)
        }
    }
    
    struct PaginatedTabResponse: Decodable {
        let data: [TabResponsePurchaseEnhanced]
        let metadata: PaginationMetadata
    }
    
    // MARK: Response GET /v1/tabs
    
    struct TabResponsePurchaseEnhanced: Decodable {
        let id: String
        let createdAt: Date
        let updatedAt: Date
        let merchantId: String?
        let userId: String
        let status: TabStatus
        let paidAt: Date?
        let total: Int
        let limit: Int
        let currency: Currency
        let paymentModel: PaymentModel
        let purchases: [PurchaseResponseEnhanced]
        let metadata: Metadata?
        let testMode: Bool
        let lpUserId: String
        let guestEmail: String?
        let tabStatistics: TabStatistics
        
        var simpleTabResponse: TabResponse {
            return TabResponse(id: id, createdAt: createdAt, updatedAt: updatedAt, merchantId: merchantId, userId: userId, status: status, paidAt: paidAt, total: total, limit: limit, currency: currency, paymentModel: paymentModel, purchases: purchases.map { $0.simplePurchaseResponse }, metadata: metadata, testMode: testMode, lpUserId: lpUserId, guestEmail: guestEmail, tabStatistics: tabStatistics)
        }
    }
    
    enum TabStatus: String, Codable {
        case open = "open"
        case full = "full"
        case closed = "closed"
    }
    
    enum Currency: String, Codable {
        case usd = "USD"
    }
    
    enum PaymentModel: String, Codable {
        case payNow = "pay_now"
        case payLater = "pay_later"
        case payMerchantLater = "pay_merchant_later"
        case payNowRecurring = "pay_now_recurring"
    }
    
    struct PurchaseResponseEnhanced: Decodable {
        let id: String
        let createdAt: Date
        let updatedAt: Date
        let purchaseDate: Date
        let merchantId: String
        let summary: String
        let price: Price
        let salesModel: SalesModel
        let paymentModel: PaymentModel
        let metadata: Metadata?
        let attributedTo: String?
        let offeringId: String
        let contentKey: String?
        let testMode: Bool
        let validFrom: Date?
        let validTo: Date?
        let validTimedelta: String?
        let recurringDetails: RecurringDetails?
        let merchantName: String
        
        var simplePurchaseResponse: PurchaseResponse {
            return PurchaseResponse(id: id, createdAt: createdAt, updatedAt: updatedAt, purchaseDate: purchaseDate, merchantId: merchantId, summary: summary, price: price, salesModel: salesModel, paymentModel: paymentModel, metadata: metadata, attributedTo: attributedTo, offeringId: offeringId, contentKey: contentKey, testMode: testMode, validFrom: validFrom, validTo: validTo, validTimedelta: validTimedelta, recurringDetails: recurringDetails)
        }
    }
    
    struct Price: Decodable, Equatable, Hashable {
        let amount: Int
        let currency: Currency
    }
    
    enum SalesModel: String, Decodable {
        case contribution = "contribution"
        case singlePurchase = "single_purchase"
        case timePass = "time_pass"
    }
    
    typealias Metadata = Dictionary<String, String>
    
    struct RecurringDetails: Decodable, Equatable, Hashable {
        let billingInterval: BillingInterval
        let intervalCount: Int
    }
    
    enum BillingInterval: String, Decodable, Equatable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
    }
    
    struct TabStatistics: Decodable, Equatable {
        let purchasesCount: Int
        let purchasesNetAmount: Int?
        let obfuscatedPurchasesCount: Int
        let obfuscatedPurchasesTotal: Int
    }
    
    struct PaginationMetadata: Decodable {
        let count: Int
        let perPage: Int
        let links: PaginationMetadataLinks
        let numberPages: Int
    }
    
    struct PaginationMetadataLinks: Decodable {
        let previous: URL?
        let next: URL?
    }
    
    // MARK: Request GET /v1/public/items/client/\(params.clientId)/config
    
    struct GetClientConfigRequestParams: Encodable {
        let clientId: String
    }
    
    class GetClientConfigRequest: GetRequest {
        init(baseUrl: URL, params: GetClientConfigRequestParams, accessToken: String) {
            super.init(path: "/v1/public/items/client/\(params.clientId)/config", baseUrl: baseUrl, accessToken: accessToken)
        }
    }
    
    
    // MARK: Response GET /v1/public/items/client/\(params.clientId)/config
    
    struct ClientConfig: Decodable, Equatable {
        let redirectUri: String
        let offerings: [SiteOffering]
        let contentKeys: [SiteContentKey]
        let siteName: String
        let testMode: Bool
    }
    
    struct SiteOffering: Decodable, Equatable, Hashable {
        let id: String
        let createdAt: Date
        let updatedAt: Date
        let itemTemplateId: String
        let description: String
        let price: Price
        var recurringDetails: RecurringDetails?
        let salesModel: SalesModel
        let paymentModel: PaymentModel
        var timePassDetails: TimePassDetails?
        let summary: String
    }
    
    struct TimePassDetails: Decodable, Equatable, Hashable {
        let validTimedelta: String
    }
    
    struct SiteContentKey: Decodable, Equatable {
        let itemTemplateId: String
        let itemOfferingIds: [String]
        let contentKey: String
    }
    
    // MARK: Request GET /v2/access/check
    
    struct CheckAccessRequestParams: Encodable {
        let contentKey: String
    }
    
    class CheckAccessRequest: GetRequest {
        init(baseUrl: URL, params: CheckAccessRequestParams, accessToken: String) {
            super.init(path: "/v2/access/check", baseUrl: baseUrl, params: params, accessToken: accessToken)
        }
    }
    
    // MARK: Response GET /v2/access/check
    
    struct AccessResponse: Decodable {
        let error: AccessError?
        let access: AccessFullResponse?
    }
    
    struct AccessError: Decodable {
        let message: String
        let code: String
    }
    
    struct AccessFullResponse: Decodable {
        let validFrom: Date
        let validTimedelta: String
        let validTo: Date
        let createdAt: Date
        let contentKey: String
        let merchantId: String
        let offeringId: String
        let purchaseId: String
        let status: AccessStatus
    }
    
    enum AccessStatus: String, Decodable {
        case granted = "Granted"
    }
    
    // MARK: Request POST /v1/purchase/\(itemOfferingId)
    
    struct PurchaseItemOfferingRequestParams: Encodable {
        let itemOfferingId: String
        
        var userId: String? // Really?
        var metadata: Metadata?
        var attributedTo: String?
    }
    
    class PurchaseItemOfferingRequest: PostRequest {
        init(baseUrl: URL, params: PurchaseItemOfferingRequestParams, accessToken: String) {
            super.init(path: "/v1/purchase/\(params.itemOfferingId)", baseUrl: baseUrl, params: params, accessToken: accessToken)
        }
    }
    
    // MARK: Response POST /v1/purchase/\(itemOfferingId)
    
    struct PurchaseItemResponse: Decodable {
        let tab: TabResponse
        let detail: PurchaseDetail
    }
    
    struct TabResponse: Decodable, Equatable {
        static var defaultCurrency = Currency.usd
        static var defaultLimit = 500
        
        let id: String
        let createdAt: Date
        let updatedAt: Date
        let merchantId: String?
        let userId: String
        let status: TabStatus
        let paidAt: Date?
        let total: Int
        let limit: Int
        let currency: Currency
        let paymentModel: PaymentModel
        let purchases: [PurchaseResponse]
        let metadata: Metadata?
        let testMode: Bool
        let lpUserId: String
        let guestEmail: String?
        let tabStatistics: TabStatistics
    }
    
    struct PurchaseResponse: Decodable, Equatable {
        let id: String
        let createdAt: Date
        let updatedAt: Date
        let purchaseDate: Date
        let merchantId: String
        let summary: String
        let price: Price
        let salesModel: SalesModel
        let paymentModel: PaymentModel
        let metadata: Metadata?
        let attributedTo: String?
        let offeringId: String
        let contentKey: String?
        let testMode: Bool
        let validFrom: Date?
        let validTo: Date?
        let validTimedelta: String?
        let recurringDetails: RecurringDetails?
    }
    
    struct PurchaseDetail: Decodable {
        let itemAdded: Bool
    }
    
    // MARK: Request GET /v1/payment/start/\(tabId)
    
    struct PaymentStartRequestParams: Encodable {
        let tabId: String
    }
    
    class PaymentStartRequest: GetRequest {
        init(baseUrl: URL, params: PaymentStartRequestParams, accessToken: String) {
            super.init(path: "/v1/payment/start/\(params.tabId)", baseUrl: baseUrl, accessToken: accessToken)
        }
    }
    
    // MARK: Response GET /v1/payment/start/\(tabId)
    
    struct PaymentStartResponse: Decodable, Equatable {
        let clientSecret: String
        let publishableKey: String
    }
    
    // MARK: Base classes
    
    class GetRequest {
        let baseUrl: URL
        let path: String
        let params: Encodable?
        let accessToken: String
        var url: URL {
            let urlEncoder = URLEncoder()
            urlEncoder.keyEncodingStrategy = .convertToSnakeCase
            var components = URLComponents()
            if let params = params {
                components.query = try! urlEncoder.encodeToString(params)
            }
            components.path = path
            return components.url(relativeTo: baseUrl)!
        }
        var urlRequest: URLRequest {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            return request
        }
        init(path: String, baseUrl: URL, params: Encodable, accessToken: String) {
            self.baseUrl = baseUrl
            self.path = path
            self.params = params
            self.accessToken = accessToken
        }
        init(path: String, baseUrl: URL, accessToken: String) {
            self.baseUrl = baseUrl
            self.path = path
            self.params = nil
            self.accessToken = accessToken
        }
    }
    
    class PostRequest: GetRequest {
        override var url: URL {
            var components = URLComponents()
            components.path = path
            return components.url(relativeTo: baseUrl)!

        }
        override var urlRequest: URLRequest {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            if let params = params {
                let jsonEncoder = JSONEncoder()
                jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
                request.httpBody = try! jsonEncoder.encode(params)
            }
            
            return request
        }
    }
}
    
