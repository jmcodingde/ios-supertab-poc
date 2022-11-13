//
//  URLEncoder.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.11.22.
//

import Foundation

class URLEncoder {
    enum EncodingError: Error {
        case failedToConvertValueToString(Any)
    }
    
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys {
        didSet {
            jsonEncoder.keyEncodingStrategy = keyEncodingStrategy
        }
    }
    var jsonEncoder = JSONEncoder()
    
    func encodeToString<T: Encodable>(_ input: T) throws -> String {
        let jsonData = try jsonEncoder.encode(input)
        let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)).flatMap { $0 as? [String: Any] }!
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        for (key, value) in dict {
            var stringValue: String?
            if let value = value as? Bool {
                stringValue = String(value)
            } else if let value = value as? Int {
                stringValue = String(value)
            } else if let value = value as? String {
                stringValue = String(value)
            } else {
                throw EncodingError.failedToConvertValueToString(value)
            }
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: stringValue!))
        }
        return urlComponents.query!
    }
    
    func encode<T: Encodable>(_ input: T) throws -> Data {
        return try encodeToString(input).data(using: String.Encoding.utf8)!
    }
}
