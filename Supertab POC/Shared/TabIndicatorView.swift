//
//  TabIndicatorView.swift
//  Supertab POC
//
//  Created by Jannes Mönnighoff on 16.10.22.
//

import SwiftUI

struct TabIndicatorView: View {
    var amount: Int
    var projectedAmount: Int
    var limit: Int
    var currencyCode: TapperClient.Currency
    var gap = Angle.degrees(30.0)
    var lineWidth: CGFloat = 8
    var fraction: Double { loading ? 0 : min(max(0, Double(amount) / Double(limit)), 1) }
    var endAngle: Angle { (.degrees(360.0) - gap) * fraction + gap / 2 }
    var projectedFraction: Double { loading ? 0 : min(max(0, Double(projectedAmount) / Double(limit)), 1) }
    var projectedEndAngle: Angle { (.degrees(360.0) - gap) * projectedFraction + gap / 2 }
    var loading = false
    
    var body: some View {
        ZStack {
            Text(loading ? "..." : formattedPrice(amount: amount, currencyCode: currencyCode))
                .bold()
                .font(.custom("Helvetica Neue Bold", size: 15))
                .foregroundColor(Color.primary)
                .id("Price")
                .transition(.scale) // TODO: find out why this is necessary
            Arc(startAngle: gap / 2, endAngle: -gap / 2, clockwise: true, rotationAdjustment: Angle.degrees(270.0))
                .strokeBorder(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .opacity(0.15)
            Arc(startAngle: gap / 2, endAngle: projectedEndAngle, clockwise: true, rotationAdjustment: Angle.degrees(270.0))
                .strokeBorder(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .opacity(0.30)
            Arc(startAngle: gap / 2, endAngle: endAngle, clockwise: true, rotationAdjustment: Angle.degrees(270.0))
                .strokeBorder(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .opacity(loading ? 0.5: 1)
    }
}

struct TabIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TabIndicatorView(amount: 150, projectedAmount: 200, limit: 500, currencyCode: .usd, loading: false)
            .frame(width: 70)
    }
}

struct Arc: InsettableShape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool
    var insetAmount: CGFloat = 0
    var rotationAdjustment: Angle = Angle.degrees(90)
    
    var animatableData: Angle.AnimatableData {
        get { endAngle.animatableData }
        set { self.endAngle.animatableData = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let modifiedStart = startAngle - rotationAdjustment
        let modifiedEnd = endAngle - rotationAdjustment
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2 - insetAmount, startAngle: modifiedStart, endAngle: modifiedEnd, clockwise: !clockwise)

        return path
    }
    
    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}

struct Arc_Previews: PreviewProvider {
    static var previews: some View {
        Arc(startAngle: .degrees(0), endAngle: .degrees(110), clockwise: true)
            .strokeBorder(Color.primary, lineWidth: 10)
            .padding()
    }
}

func formattedPrice(amount: Int, currencyCode: TapperClient.Currency, hideDoubleZeroFractionDigits: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.locale = .init(identifier: "en-US")
    formatter.numberStyle = .currency
    formatter.currencyCode = currencyCode.rawValue
    let formattedAmount = formatter.string(from: NSNumber(value: Double(amount)/100)) ?? "0"
    if hideDoubleZeroFractionDigits {
        return formattedAmount.replacingOccurrences(of: ".00", with: "")
    }
    else {
        return formattedAmount
    }
}

struct FormattedPrice_Previews: PreviewProvider {
    static var previews: some View {
        Text(formattedPrice(amount: 150, currencyCode: .usd)).bold()
    }
}
