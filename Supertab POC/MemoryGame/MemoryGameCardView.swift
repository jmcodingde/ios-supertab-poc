//
//  CardView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 14.10.22.
//

import SwiftUI

struct MemoryGameCardView: View {
    @ObservedObject var card: MemoryGameCardMachine
    var onTap: () -> Void
    let cardCornerRadius = 25.0;
    
    var body: some View {
        Button(action: onTap) {
            Text(card.currentState == .cover ? card.context.cover : card.context.face)
                .font(.largeTitle)
                .padding()
                .foregroundColor(Color.primary)
                .frame(width: 80, height: 80)
                .overlay(RoundedRectangle(cornerRadius: cardCornerRadius).stroke(Color.primary, lineWidth: 1))
        }
    }
}

struct MemoryGameCardView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryGameCardView(card: MemoryGameCardMachine(face: "👍"), onTap: {})
    }
}
