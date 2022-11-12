//
//  URLEncoder.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.11.22.
//

import Foundation

class URLEncoder {
    var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys {
        didSet {
            jsonEncoder.keyEncodingStrategy = keyEncodingStrategy
        }
    }
    var jsonEncoder = JSONEncoder()
    
    func encodeToString<T: Encodable>(_ input: T) throws -> String {
        let jsonData = try jsonEncoder.encode(input)
        let dict = (try? JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)).flatMap { $0 as? [String: String] }!
        var urlComponents = URLComponents()
        urlComponents.queryItems = []
        for (key, value) in dict {
            urlComponents.queryItems?.append(URLQueryItem(name: key, value: String(value)))
        }
        return urlComponents.query!
    }
    
    func encode<T: Encodable>(_ input: T) throws -> Data {
        return try encodeToString(input).data(using: String.Encoding.utf8)!
    }
}
