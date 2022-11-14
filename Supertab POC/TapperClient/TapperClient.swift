//
//  TapperClient.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 13.11.22.
//

import Foundation

class TapperClient {
    let apiBaseUrl = URL(string: "https://tapi.laterpay.net")!
    let authorizeUrl = URL(string: "https://auth.laterpay.net/oauth2/auth")!
    let tokenUrl = URL(string: "https://auth.laterpay.net/oauth2/token")!
    let redirectUri = URL(string: "https://ios.poc.laterpay.net/api/oauth2/callback/supertab-poc")!
    let clientId = "client.c3c9e7ee-ab50-4cca-91f0-a1153b87ad4d"
    let currency: Currency = .usd
    let paymentModel: PaymentModel = .payLater
    let callbackURLScheme = "supertab-poc"
    let oauth2PkceSession: OAuth2PKCESession
    var apiTokens: AccessTokenResponseEnhanced?
    let jsonDecoder: JSONDecoder
    let goJsonDecoder: JSONDecoder
    
    init() {
        oauth2PkceSession = OAuth2PKCESession(authorizeUrl: authorizeUrl, tokenUrl: tokenUrl, redirectUri: redirectUri, clientId: clientId, callbackURLScheme: callbackURLScheme)
        
        jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonDecoder.dateDecodingStrategy = .iso8601withFractionalSeconds
        
        goJsonDecoder = JSONDecoder()
        goJsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        goJsonDecoder.dateDecodingStrategy = .secondsSince1970
    }
    
    enum RequestError: LocalizedError {
        case unexpectedResponseStatusCode(Int, URL)
        case missingApiTokens
        
        func localizedDescription() -> String {
            switch self {
            case .unexpectedResponseStatusCode(let statusCode, let url):
                return "Unexpected response status code: \(statusCode) from \(url.formatted())"
            case .missingApiTokens:
                return "Missing API tokens"
            }
        }
    }
    
    func authenticate() async throws {
        print("Fetching API tokens...")
        apiTokens = try await oauth2PkceSession.authenticate()
    }

    func ensureValidAccessToken() async throws {
        if apiTokens == nil {
            try await authenticate()
        }
        guard let apiTokens = apiTokens else { throw RequestError.missingApiTokens }
        print("Access token expires at \(apiTokens.expiresAt)")
        let expiresIn = Int(apiTokens.expiresAt.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate)
        print("Access token expires in \(expiresIn)")
        if expiresIn < 60 {
            print("Access token will expire soon or is already expired, attempting to refresh...")
            do {
                self.apiTokens = try await oauth2PkceSession.getAccessToken(refreshToken: apiTokens.refreshToken)
            } catch (let error) {
                print(error.localizedDescription)
                try await authenticate()
            }
        }
    }
    
    func fetchActiveTab() async throws -> TabResponsePurchaseEnhanced? {
        try await ensureValidAccessToken()
        guard let apiTokens = apiTokens else { throw RequestError.missingApiTokens }
        
        print("Fetching tabs...")// with API tokens: \(apiTokens!)")
        let params = PaginatedTabRequestParams(paymentModel: paymentModel, currency: currency, isActive: true)
        let request = PaginatedTabRequest(baseUrl: apiBaseUrl, params: params, accessToken: apiTokens.accessToken).urlRequest
        
        print("Requesting URL \(request.url!)")
        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        let response = rawResponse as! HTTPURLResponse
        switch response.statusCode {
        case 200:
            let result = try! jsonDecoder.decode(PaginatedTabResponse.self, from: data)
            print("Received response: \(result)")
            return result.data.count > 0 ? result.data[0] : nil
        default:
            print("Raw response: \(String(decoding: data, as: UTF8.self))")
            throw RequestError.unexpectedResponseStatusCode(response.statusCode, request.url!)
        }
    }
    
    func fetchClientConfigFor(clientId: String) async throws -> ClientConfig {
        try await ensureValidAccessToken()
        guard let apiTokens = apiTokens else { throw RequestError.missingApiTokens }
        
        print("Fetching client config...")
        let params = GetClientConfigRequestParams(clientId: clientId)
        let request = GetClientConfigRequest(baseUrl: apiBaseUrl, params: params, accessToken: apiTokens.accessToken).urlRequest
        
        print("Requesting URL \(request.url!)")
        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        let response = rawResponse as! HTTPURLResponse
        switch response.statusCode {
        case 200:
            let result = try! jsonDecoder.decode(ClientConfig.self, from: data)
            print("Received response: \(result)")
            return result
        default:
            print("Raw response: \(String(decoding: data, as: UTF8.self))")
            throw RequestError.unexpectedResponseStatusCode(response.statusCode, request.url!)
        }
    }
    
    func checkAccessTo(contentKey: String) async throws -> AccessResponse {
        try await ensureValidAccessToken()
        guard let apiTokens = apiTokens else { throw RequestError.missingApiTokens }
        
        print("Checking access...")
        let params = CheckAccessRequestParams(contentKey: contentKey)
        let request = CheckAccessRequest(baseUrl: apiBaseUrl, params: params, accessToken: apiTokens.accessToken).urlRequest
        
        print("Requesting URL \(request.url!)")
        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        let response = rawResponse as! HTTPURLResponse
        switch response.statusCode {
        case 200:
            let result = try! goJsonDecoder.decode(AccessResponse.self, from: data)
            print("Received response: \(result)")
            return result
        default:
            print("Raw response: \(String(decoding: data, as: UTF8.self))")
            throw RequestError.unexpectedResponseStatusCode(response.statusCode, request.url!)
        }
    }
    
    func purchase(itemOfferingId: String, metadata: Metadata? = nil) async throws -> PurchaseItemResponse {
        try await ensureValidAccessToken()
        guard let apiTokens = apiTokens else { throw RequestError.missingApiTokens }
        
        print("Purchasing...")
        let params = PurchaseItemOfferingRequestParams(itemOfferingId: itemOfferingId, metadata: metadata)
        let request = PurchaseItemOfferingRequest(baseUrl: apiBaseUrl, params: params, accessToken: apiTokens.accessToken).urlRequest
        
        print("Requesting URL \(request.url!)")
        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        let response = rawResponse as! HTTPURLResponse
        switch response.statusCode {
        case 201, 402:
            let result = try! jsonDecoder.decode(PurchaseItemResponse.self, from: data)
            print("Received response: \(result)")
            return result
        default:
            print("Raw response: \(String(decoding: data, as: UTF8.self))")
            throw RequestError.unexpectedResponseStatusCode(response.statusCode, request.url!)
        }
    }

    func startPaymentFor(tabId: String) async throws -> PaymentStartResponse {
        try await ensureValidAccessToken()
        guard let apiTokens = apiTokens else { throw RequestError.missingApiTokens }
        
        print("Starting payment...")
        let params = PaymentStartRequestParams(tabId: tabId)
        let request = PaymentStartRequest(baseUrl: apiBaseUrl, params: params, accessToken: apiTokens.accessToken).urlRequest
        
        print("Requesting URL \(request.url!)")
        let (data, rawResponse) = try await URLSession.shared.data(for: request)
        let response = rawResponse as! HTTPURLResponse
        switch response.statusCode {
        case 200:
            let result = try! jsonDecoder.decode(PaymentStartResponse.self, from: data)
            print("Received response: \(result)")
            return result
        default:
            print("Raw response: \(String(decoding: data, as: UTF8.self))")
            throw RequestError.unexpectedResponseStatusCode(response.statusCode, request.url!)
        }
    }
}
