//
//  DateFormatter.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 13.11.22.
//
//  Adds support for iso8601 date encoding and decoding with fractional seconds
//
//  https://gist.github.com/Ikloo/e0011c99665dff0dd8c4d116150f9129
//

import Foundation

extension Formatter {
    static let iso8601: (regular: ISO8601DateFormatter, withFractionalSeconds: ISO8601DateFormatter) = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return (ISO8601DateFormatter(), formatter)
      }()
}
extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = Formatter.iso8601.withFractionalSeconds.date(from: string) {
            return date
        } else if let date = Formatter.iso8601.regular.date(from: string) {
            return date
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: " + string)
        }
    }
}
extension JSONEncoder.DateEncodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        var container = $1.singleValueContainer()
        try container.encode(Formatter.iso8601.withFractionalSeconds.string(from: $0))
    }
}
