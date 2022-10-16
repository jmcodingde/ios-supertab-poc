//
//  MemoryMachine.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import Foundation

let initialMemoryGameState = MemoryGameState.awaitingFirstCardSelection

enum MemoryGameState: Equatable {
    case awaitingFirstCardSelection
    case awaitingSecondCardSelection
    case won
    case lost
}

enum MemoryGameEvent {
    case tapCard(MemoryGameCardMachine)
    case reset
}

enum MemoryGameGuards {
    static func isMatch(_ context: MemoryGameContext) -> Bool {
        let openCards = MemoryGameUtils.findPeekingCards(context)
        if openCards.count != 2 {
            return false
        }
        return openCards[0] !== openCards[1] && openCards[0].context.face == openCards[1].context.face
    }
    static func hasLost(_ context: MemoryGameContext) -> Bool {
        return context.numMismatchesLeft <= 0
    }
    static func hasWon(_ context: MemoryGameContext) -> Bool {
        for card in context.cards {
            if card.currentState != .matched {
                return false
            }
        }
        return true
    }
}

enum MemoryGameUtils {
    static func findPeekingCards(_ context: MemoryGameContext) -> [MemoryGameCardMachine] {
        return context.cards.filter { $0.currentState == .peeking }
    }
}

enum MemoryGameActions {
    static func markMatch(_ context: MemoryGameContext) {
        MemoryGameUtils.findPeekingCards(context).forEach { $0.send(.match) }
    }
    static func hidePeeking(_ context: MemoryGameContext) {
        MemoryGameUtils.findPeekingCards(context).forEach { $0.send(.hide) }
    }
    static func decrNumMismatchesLeft(_ context: MemoryGameContext) -> MemoryGameContext {
        var _context = context
        _context.numMismatchesLeft -= 1
        return _context
    }
    static func resetAllCards(_ context: MemoryGameContext) {
        context.cards.forEach { $0.send(.reset) }
    }
    static func shuffleAllCards(_ context: MemoryGameContext) -> MemoryGameContext {
        var _context = context
        _context.cards = _context.cards.shuffled()
        return _context
    }
    static func resetNumMismatchesLeft(_ context: MemoryGameContext) -> MemoryGameContext {
        var _context = context
        _context.numMismatchesLeft = _context.allowedNumMismatches
        return _context
    }
}

struct MemoryGameContext {
    let numRows: Int
    let numCols: Int
    var numMismatchesLeft: Int
    let allowedNumMismatches: Int
    var cards: [MemoryGameCardMachine]
    init(numRows: Int, numCols: Int, faces: [String], allowedNumMismatches: Int) throws {
        self.numRows = numRows
        self.numCols = numCols
        self.numMismatchesLeft = allowedNumMismatches
        self.allowedNumMismatches = allowedNumMismatches
        if(faces.count != numCols * numRows / 2) {
            throw "Faces count mismatch: need \(numRows) * \(numCols) / 2 = \(numCols * numRows / 2) but got only \(faces.count)"
        }
        self.cards = (faces + faces).map({ face in
            MemoryGameCardMachine(face: face)
        }).shuffled()
    }
}

class MemoryGameMachine: ObservableObject {
    let faces = [ "😀", "😃", "😄", "😁", "😆", "🥹", "😅", "😂", "🤣", "🥲" ]
    @Published private(set) var currentState = initialMemoryGameState
    @Published private(set) var context: MemoryGameContext
    
    init() {
        context = try! MemoryGameContext(numRows: 5, numCols: 4, faces: faces, allowedNumMismatches: 10)
    }

    func send(_ event: MemoryGameEvent) {
        print(currentState)
        switch(currentState, event) {
        case (.awaitingFirstCardSelection, .tapCard(let card)):
            MemoryGameActions.hidePeeking(context)
            card.send(.show)
            currentState = .awaitingSecondCardSelection
        case (.awaitingSecondCardSelection, .tapCard(let card)):
            switch(card.currentState) {
            case .cover:
                card.send(.show)
                if MemoryGameGuards.isMatch(context) {
                    MemoryGameActions.markMatch(context)
                    if MemoryGameGuards.hasWon(context) {
                        print("Won")
                        currentState = .won
                    }
                    else {
                        currentState = .awaitingFirstCardSelection
                    }
                } else {
                    context = MemoryGameActions.decrNumMismatchesLeft(context)
                    if MemoryGameGuards.hasLost(context) {
                        print("Lost")
                        currentState = .lost
                    }
                    else {
                        currentState = .awaitingFirstCardSelection
                    }
                }
            case .peeking:
                print("Already peeking")
            case .matched:
                print("Already matched")
            }
        case (_, .reset):
            print("Resetting")
            MemoryGameActions.resetAllCards(context)
            context = MemoryGameActions.shuffleAllCards(context)
            context = MemoryGameActions.resetNumMismatchesLeft(context)
            currentState = initialMemoryGameState
        default:
            print("Can not handle event \(event) in state \(currentState)")
        }
        
    }
}