//
//  OfferingsList.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 04.01.23.
//

import SwiftUI

struct OfferingsList: View {
    let offerings: [Offering]
    let selectedOffering: Offering?
    let offeringsMetadata: [Metadata]
    let isLoading: Bool
    let onSelectOffering: (Offering) -> Void
    
    var body: some View {
        HStack {
            ForEach(offerings.indices, id: \.self) { index in
                let offering = offerings[index]
                let isSelected = offering == selectedOffering
                let summary = offeringsMetadata[index]["summary"] ?? offering.summary
                Button {
                    onSelectOffering(offering)
                } label: {
                    VStack {
                        Text(formattedPrice(amount: offering.price.amount, currencyCode: offering.price.currency)).font(.custom("Helvetica Neue Bold", size: 16)).tracking(0.16)
                        Text(summary).font(.custom("Helvetica Neue Regular", size: 12)).tracking(0.12)
                    }
                    .frame(height: 55)
                    .foregroundColor(isSelected ? Color(UIColor.systemBackground) : .primary)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: .infinity)
                            .stroke(Color.primary, lineWidth: 3)
                            .opacity(isLoading ? 0.4 : isSelected ? 1 : 0.1)
                    )
                    
                }
                .background(isSelected ? Color.primary : Color(UIColor.systemBackground))
                .clipShape(Capsule())
                .shadow(color: .primary.opacity(isSelected ? 0 : 0.1), radius: 8, x: 0, y: 4)
                
            }
        }
    }
}

// MARK: Preview

struct OfferingsListInteractivePreview: View {
    let offerings = [
        Offering(id: "offering-1", createdAt: Date.now, updatedAt: Date.now, itemTemplateId: "template-1", description: "Description 1", price: Price(amount: 50, currency: .usd), salesModel: .timePass, paymentModel: .payLater, summary: "Offering Summary 1"),
        Offering(id: "offering-2", createdAt: Date.now, updatedAt: Date.now, itemTemplateId: "template-2", description: "Description 2", price: Price(amount: 100, currency: .usd), salesModel: .timePass, paymentModel: .payLater, summary: "Offering Summary 2"),
        Offering(id: "offering-3", createdAt: Date.now, updatedAt: Date.now, itemTemplateId: "template-3", description: "Description 3", price: Price(amount: 200, currency: .usd), salesModel: .timePass, paymentModel: .payLater, summary: "Offering Summary 3")
    ]
    @State var selectedOffering: Offering?
    let metadata = [
        ["summary": "Summary 1"],
        ["summary": "Summary 2"],
        ["summary": "Summary 3"]
    ]
    let isLoading = false
    
    func onSelectOffering(offering: Offering) -> Void {
        print(offering)
        selectedOffering = offering
    }
    
    var body: some View {
        OfferingsList(
            offerings: offerings,
            selectedOffering: selectedOffering,
            offeringsMetadata: metadata,
            isLoading: isLoading,
            onSelectOffering: onSelectOffering
        )
        .padding()
    }
}

struct OfferingsList_Previews: PreviewProvider {
    static var previews: some View {
        OfferingsListInteractivePreview()
    }
}
