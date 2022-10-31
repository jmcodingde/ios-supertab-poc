//
//  Supertab_POCApp.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 12.10.22.
//

import SwiftUI

extension String: Error {}

// https://www.swiftbysundell.com/articles/async-and-concurrent-forEach-and-map/
extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
    try await transform(element)
}
        }

        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}

@main
struct Supertab_POCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
