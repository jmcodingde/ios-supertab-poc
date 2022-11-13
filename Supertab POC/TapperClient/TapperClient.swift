//
//  TapperClient.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 13.11.22.
//

import Foundation

class TapperClient {
    let apiBaseUrl = URL(string: "https://tapi.sbx.laterpay.net")!
    let authorizeUrl = URL(string: "https://auth.sbx.laterpay.net/oauth2/auth")!
    let tokenUrl = URL(string: "https://auth.sbx.laterpay.net/oauth2/token")!
    let redirectUri = URL(string: "https://e8fe-62-226-109-75.ngrok.io/api/oauth2/callback/supertab-poc")!
    let clientId = "client.4d1a76a9-27ba-4ae6-8045-a581af101476"
    let currency: Currency = .usd
    let paymentModel: PaymentModel = .payLater
    let callbackURLScheme = "supertab-poc"
    let oauth2PkceSession: OAuth2PKCESession
    var apiTokens: AccessTokenResponse?
    let jsonDecoder: JSONDecoder
    
    init() {
        oauth2PkceSession = OAuth2PKCESession(authorizeUrl: authorizeUrl, tokenUrl: tokenUrl, redirectUri: redirectUri, clientId: clientId, callbackURLScheme: callbackURLScheme)
        jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonDecoder.dateDecodingStrategy = .iso8601withFractionalSeconds
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
    
    func fetchActiveTab() async throws -> TabResponsePurchaseEnhanced? {
        if apiTokens == nil {
            print("Fetching API tokens...")
            apiTokens = try await oauth2PkceSession.authenticate()
        }
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
}
