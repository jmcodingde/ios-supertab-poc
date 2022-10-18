//
//  MemoryGameCardMachine.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import Foundation

let memoryGameCardInitialState = MemoryGameCardState.cover

enum MemoryGameCardState: Equatable {
    case cover
    case peeking
    case matched
}

enum MemoryGameCardEvent {
    case show
    case hide
    case match
    case reset
}

struct MemoryGameCardContext: Equatable {
    let face: String;
    let cover: String;
}

class MemoryGameCardMachine: ObservableObject {
    @Published private(set) var currentState = memoryGameCardInitialState
    @Published private(set) var context: MemoryGameCardContext;
    
    init(face: String, cover: String = "") {
        context = MemoryGameCardContext(face: face, cover: cover)
    }
    
    func send(_ event: MemoryGameCardEvent) {
        switch(currentState, event) {
        case (.cover, .show):
            print("Showing \(context.face)")
            currentState = .peeking
        case (.peeking, .hide):
            print("Hiding \(context.face)")
            currentState = .cover
        case (.peeking, .match):
            print("Match \(context.face)")
            currentState = .matched
        case (_, .reset):
            print("Resetting \(context.face)")
            currentState = .cover
        default:
            print("Cannot handle event \(event) in state \(currentState)")
        }
    }
}
