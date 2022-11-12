//
//  OAuth.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 11.11.22.
//  Heaviliy inspired by https://github.com/MarcoEidinger/pkce-ios-swift-auth0server/blob/main/AppUsingPKCE/OAuth2PKCEAuthenticator.swift
//

import Foundation
import Combine
import AuthenticationServices
import CommonCrypto
import CryptoKit

enum OAuth2PKCEAuthenticatorError: LocalizedError {
    case authRequestFailed(Error)
    case authorizeResponseNoUrl
    case authorizeResponseNoCode
    case authorizeResponseNoState
    case authorizeResponseStateMismatch
    case tokenRequestFailed(Error)
    case tokenResponseNoData
    case tokenResponseInvalidData(String)
    case failedToGenerateRandomOctets
    case failedToCreateChallengeForVerifier
    
    var localizedDescription: String {
        switch self {
        case .authRequestFailed(let error):
            return "authorization request failed: \(error.localizedDescription)"
        case .authorizeResponseNoUrl:
            return "authorization response does not include a url"
        case .authorizeResponseNoCode:
            return "authorization response does not include a code"
        case .authorizeResponseNoState:
            return "authorization response does not include a state"
        case .authorizeResponseStateMismatch:
            return "state in authorization response does not match the initial state"
        case .tokenRequestFailed(let error):
            return "token request failed: \(error.localizedDescription)"
        case .tokenResponseNoData:
            return "no data received as part of token response"
        case .tokenResponseInvalidData(let reason):
            return "invalid data received as part of token response: \(reason)"
        case .failedToGenerateRandomOctets:
            return "failed to generate random octets for code challenge"
        case .failedToCreateChallengeForVerifier:
            return "failed to create code challenge for code verifier"
            
        }
    }
}

struct AccessTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct AccessTokenRequestBody: Encodable {
    let grantType: String = "authorization_code"
    let clientId: String
    let codeVerifier: String
    let code: String
    let redirectUri: String
}

struct AccessTokenRefreshRequestBody: Encodable {
    let grantType: String = "refresh_token"
    let clientId: String
    let refreshToken: String
}

struct AuthorizationUrlParameters: Encodable {
    let responseType: String = "code"
    let codeChallenge: String
    let codeChallengeMethod: String = "S256"
    let clientId: String
    let redirectUri: String
    let state: String
}

class OAuth2PKCESession: NSObject {
    
    let authorizeUrl: String
    let logoutUrl: String
    let tokenUrl: String
    let clientId: String
    let redirectUri: String
    let callbackURLScheme: String
    let jsonDecoder: JSONDecoder
    let jsonEncoder: JSONEncoder
    let urlEncoder: URLEncoder
    
    init(authorizeUrl: String, logoutUrl: String, tokenUrl: String, clientId: String, redirectUri: String, callbackURLScheme: String) {
        self.authorizeUrl = authorizeUrl
        self.logoutUrl = logoutUrl
        self.tokenUrl = tokenUrl
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.callbackURLScheme = callbackURLScheme
        self.jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        self.jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        self.urlEncoder = URLEncoder()
        urlEncoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    public func authenticate() async throws -> AccessTokenResponse {
        return try await authenticate(url: authorizeUrl)
    }

    private func authenticate(url: String) async throws -> AccessTokenResponse {
        // 1. create a random state parameter
        let state = createRandomString(length: 16)
        // 2. and a cryptographically-random codeVerifier
        let codeVerifier = try createCodeVerifier()
        // 3. and from this generate a codeChallenge
        let codeChallenge = try createCodeChallenge(for: codeVerifier)
        // 4. get authCode by redirecting the user to the authorization server along with the codeChallenge
        let authUrlParams = AuthorizationUrlParameters(codeChallenge: codeChallenge, clientId: clientId, redirectUri: redirectUri, state: state)
        var authUrlComponents = URLComponents(string: url)!
        authUrlComponents.query = try urlEncoder.encodeToString(authUrlParams)
        let authCode: String = try await startWebAuthenticationSession(url: authUrlComponents.url!, state: state, codeVerifier: codeVerifier, codeChallenge: codeChallenge)
        // 5. use authCode and codeVerifier to fetch accessToken and refreshToken
        let tokenResponse = try await getAccessToken(authCode: authCode, codeVerifier: codeVerifier)
        return tokenResponse
    }
    
    private func startWebAuthenticationSession(url: URL, state: String, codeVerifier: String, codeChallenge: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let authenticationSession = ASWebAuthenticationSession(url: url, callbackURLScheme: self.callbackURLScheme) { optionalUrl, optionalError in
                // authorization server stores the code_challenge and redirects the user back to the application with an authorization code, which is good for one use
                guard optionalError == nil else { continuation.resume(throwing: OAuth2PKCEAuthenticatorError.authRequestFailed(optionalError!)); return }
                guard let url = optionalUrl else { continuation.resume(throwing: OAuth2PKCEAuthenticatorError.authorizeResponseNoUrl); return }
                guard let authCode = self.getQueryStringParameter("code", from: url) else { continuation.resume(throwing: OAuth2PKCEAuthenticatorError.authorizeResponseNoCode); return }
                guard let responseState = self.getQueryStringParameter("state", from: url) else { continuation.resume(throwing: OAuth2PKCEAuthenticatorError.authorizeResponseNoState); return }
                guard responseState == state else { continuation.resume(throwing: OAuth2PKCEAuthenticatorError.authorizeResponseStateMismatch); return }
                continuation.resume(returning: authCode)
            }
            authenticationSession.presentationContextProvider = self
            authenticationSession.prefersEphemeralWebBrowserSession = false
            DispatchQueue.main.async {
                authenticationSession.start()
            }
        }
    }
    
    private func createCodeVerifier() throws -> String {
        let octets = try generateCryptographicallySecureRandomOctets(count: 32)
        return base64URLEncode(octets: octets)
    }
    
    private func generateCryptographicallySecureRandomOctets(count: Int) throws -> [UInt8] {
        var octets = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, octets.count, &octets)
        if status == errSecSuccess { // Always test the status.
            return octets
        } else {
            throw OAuth2PKCEAuthenticatorError.failedToGenerateRandomOctets
        }
    }
    
    private func base64URLEncode<S>(octets: S) -> String where S : Sequence, UInt8 == S.Element {
        let data = Data(octets)
        return data
            .base64EncodedString() // Regular base64 encoder
            .replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
            .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
            .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func createCodeChallenge(for verifier: String) throws -> String {
        let challenge = verifier
            .data(using: .ascii) // (a)
            .map { SHA256.hash(data: $0) } // (b)
            .map { base64URLEncode(octets: $0) } // (c)

        if let challenge = challenge {
            return challenge
        } else {
            throw OAuth2PKCEAuthenticatorError.failedToCreateChallengeForVerifier
        }
    }
    
    private func getAccessToken(authCode: String, codeVerifier: String) async throws -> AccessTokenResponse {
        let accessTokenRequestBody = AccessTokenRequestBody(clientId: clientId, codeVerifier: codeVerifier, code: authCode, redirectUri: redirectUri)
        let httpBody = try urlEncoder.encode(accessTokenRequestBody)
        let tokenResponse = try await getAccessToken(httpBody: httpBody)
        print("Received response from token request using authCode and codeVerifier: \(tokenResponse)")
        return tokenResponse
    }
    
    private func getAccessToken(refreshToken: String) async throws -> AccessTokenResponse {
        let accessTokenRefreshRequestBody = AccessTokenRefreshRequestBody(clientId: clientId, refreshToken: refreshToken)
        let httpBody = try urlEncoder.encode(accessTokenRefreshRequestBody)
        let tokenResponse = try await getAccessToken(httpBody: httpBody)
        print("Received response from token request using refreshToken: \(tokenResponse)")
        return tokenResponse
    }
    
    private func getAccessToken(httpBody: Data) async throws -> AccessTokenResponse {
        let url = URL(string: tokenUrl)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = ["content-type": "application/x-www-form-urlencoded"]
        request.httpBody = httpBody
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let tokenResponse = try jsonDecoder.decode(AccessTokenResponse.self, from: data)
                return tokenResponse
            } catch {
                let reason = String(data: data, encoding: .utf8) ?? "Unknown"
                throw OAuth2PKCEAuthenticatorError.tokenResponseInvalidData(reason)
            }
        } catch (let error) {
            throw OAuth2PKCEAuthenticatorError.tokenRequestFailed(error)
        }
    }
    
    func getQueryStringParameter(url: String, param: String) -> String? {
        guard let url = URLComponents(string: url) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
    
    func createRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func getQueryStringParameter(_ parameter: String, from url: URL) -> String? {
        guard let urlComponents = URLComponents(string: url.absoluteString) else { return nil }
        return urlComponents.queryItems?.first(where: { $0.name == parameter })?.value
    }
}

extension OAuth2PKCESession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
