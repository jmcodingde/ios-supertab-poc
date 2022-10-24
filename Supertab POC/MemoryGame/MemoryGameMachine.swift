//
//  MemoryMachine.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import Foundation
import SwiftUI

let initialMemoryGameState = MemoryGameState.awaitingFirstCardSelection

enum MemoryGameState: Equatable {
    case awaitingFirstCardSelection
    case awaitingSecondCardSelection
    case won
    case lost
}

enum MemoryGameEvent {
    case tapCard(MemoryGameCardMachine)
    case addGames(_ numGames: Int)
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
    var gamesLeft: Int
    var isDirty: Bool {
        return cards.contains { card in card.currentState != .cover }
    }
    init(numRows: Int, numCols: Int, faces: [String], allowedNumMismatches: Int, gamesLeft: Int) throws {
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
        self.gamesLeft = gamesLeft
    }
}

class MemoryGameMachine: ObservableObject {
    let faces = [ "😀", "😃", "😄", "😁", "😆", "🥹", "😅", "😂", "🤣", "🥲" ]
    @Published private(set) var currentState = initialMemoryGameState
    @Published private(set) var context: MemoryGameContext
    
    init(numGames: Int = -1) {
        context = try! MemoryGameContext(numRows: 5, numCols: 4, faces: faces, allowedNumMismatches: 10, gamesLeft: numGames)
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
        case (.won ,.reset):
            MemoryGameActions.resetAllCards(context)
            context = MemoryGameActions.shuffleAllCards(context)
            context = MemoryGameActions.resetNumMismatchesLeft(context)
            currentState = initialMemoryGameState
        case (_, .reset):
            func reset() {
                MemoryGameActions.resetAllCards(context)
                context = MemoryGameActions.shuffleAllCards(context)
                context = MemoryGameActions.resetNumMismatchesLeft(context)
                currentState = initialMemoryGameState
            }
            if context.gamesLeft == -1 {
                print("Resetting (not counting games)")
                reset()
            } else if context.gamesLeft > 0 {
                print("Resetting (games left: \(context.gamesLeft)")
                context.gamesLeft -= 1
                reset()
            } else {
                print("Cannot reset game because there are no games left")
            }
        case (_, .addGames(let numGames)):
            context.gamesLeft += numGames
        default:
            print("Cannot handle event \(event) in state \(currentState)")
        }
        
    }
}
