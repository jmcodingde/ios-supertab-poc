//
//  Schema.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 13.11.22.
//

import Foundation

extension TapperClient {
    
    struct PaginatedTabResponse: Codable {
        let data: [TabResponsePurchaseEnhanced]
        let metadata: PaginationMetadata
    }
    
    struct TabResponsePurchaseEnhanced: Codable {
        let id: String
        let createdAt: String
        let updatedAt: String
        let merchantId: String?
        let userId: String
        let status: TabStatus
        let paidAt: String?
        let total: Int
        let limit: Int
        let currency: Currency
        let paymentModel: String
        let purchases: [PurchaseResponseEnhanced]
        let metadata: Metadata?
        let testMode: Bool
        let lpUserId: String
        let guestEmail: String?
        let tabStatistics: TabStatistics
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
    
    struct PurchaseResponseEnhanced: Codable {
        let id: String
        let createdAt: String
        let updatedAt: String
        let purchaseDate: String
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
        let validFrom: String?
        let validTo: String?
        let validTimedelta: String?
        let recurringDetails: String?
        let merchantName: String
    }
    
    struct Price: Codable {
        let amount: Int
        let currency: Currency
    }
    
    enum SalesModel: String, Codable {
        case contribution = "contribution"
        case singlePurchase = "single_purchase"
        case timePass = "time_pass"
    }
    
    typealias Metadata = Dictionary<String, String>
    
    struct RecurringDetails: Codable {
        let billingInterval: BillingInterval
        let intervalCount: Int
    }
    
    enum BillingInterval: String, Codable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
    }
    
    struct TabStatistics: Codable {
        let purchasesCount: Int
        let purchasesNetAmount: Int?
        let obfuscatedPurchasesCount: Int
        let obfuscatedPurchasesTotal: Int
    }
    
    struct PaginationMetadata: Codable {
        let count: Int
        let perPage: Int
        let links: PaginationMetadataLinks
        let numberPages: Int
    }
    
    struct PaginationMetadataLinks: Codable {
        let previous: URL?
        let next: URL?
    }
    
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
    
    class GetRequest {
        let baseUrl: URL
        let path: String
        let params: PaginatedTabRequestParams
        let accessToken: String
        var url: URL {
            let urlEncoder = URLEncoder()
            urlEncoder.keyEncodingStrategy = .convertToSnakeCase
            var components = URLComponents()
            components.query = try! urlEncoder.encodeToString(params)
            components.path = path
            return components.url(relativeTo: baseUrl)!
        }
        var urlRequest: URLRequest {
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            return request
        }
        init(path: String, baseUrl: URL, params: PaginatedTabRequestParams, accessToken: String) {
            self.baseUrl = baseUrl
            self.path = path
            self.params = params
            self.accessToken = accessToken
        }
    }
}
